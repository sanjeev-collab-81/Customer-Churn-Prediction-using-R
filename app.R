# app.R
library(shiny)
library(bslib)
library(tidymodels)
library(dplyr)
library(plotly)
library(DT)
library(randomForest)

# Load data and model
# Assuming the scripts have been run
if(!file.exists("models/model.rds") || !file.exists("data/raw_data.rds")) {
  stop("Model or data not found. Please run R/data_prep.R and R/train_model.R first.")
}

final_model <- readRDS("models/model.rds")
raw_data <- readRDS("data/raw_data.rds")
test_preds <- readRDS("models/test_preds.rds")

# Ensure required packages for bslib themes are available
theme <- bs_theme(version = 5, preset = "minty")

ui <- page_sidebar(
  title = "Customer Churn Prediction",
  theme = theme,
  
  sidebar = sidebar(
    title = "Customer Profile",
    selectInput("customer_selector", "Select Existing Customer:", 
                choices = c("New Custom Profile" = "new", raw_data$customer_id[1:100])),
    
    # Inputs for features
    numericInput("tenure_months", "Tenure (Months):", value = 12, min = 0, max = 72),
    selectInput("contract_type", "Contract Type:", choices = c("Month-to-month", "One year", "Two year")),
    numericInput("monthly_charges", "Monthly Charges ($):", value = 50, min = 15, max = 120),
    selectInput("internet_service", "Internet Service:", choices = c("DSL", "Fiber optic", "No")),
    selectInput("tech_support", "Tech Support:", choices = c("Yes", "No", "No internet service")),
    selectInput("payment_method", "Payment Method:", choices = c("Electronic check", "Mailed check", "Bank transfer (automatic)", "Credit card (automatic)")),
    selectInput("senior_citizen", "Senior Citizen:", choices = c("No", "Yes")),
    selectInput("partner", "Partner:", choices = c("No", "Yes")),
    selectInput("dependents", "Dependents:", choices = c("No", "Yes")),
    
    actionButton("predict_btn", "Predict Churn Risk", class = "btn-primary", width = "100%"),
    br(),
    
    # Results area in sidebar
    uiOutput("prediction_result"),
    plotlyOutput("gauge_chart", height = "200px")
  ),
  
  navset_card_tab(
    nav_panel("Dashboard",
      layout_columns(
        value_box(
          title = "Overall Churn Rate",
          value = textOutput("overall_churn"),
          theme = "primary",
          showcase = bsicons::bs_icon("people")
        ),
        value_box(
          title = "Total Customers",
          value = nrow(raw_data),
          theme = "info",
          showcase = bsicons::bs_icon("person-lines-fill")
        )
      ),
      layout_columns(
        card(
          card_header("Churn Rate by Contract Type"),
          plotlyOutput("contract_chart")
        ),
        card(
          card_header("Churn Rate by Tenure"),
          plotlyOutput("tenure_chart")
        )
      ),
      card(
        card_header("Feature Importance"),
        plotlyOutput("importance_chart")
      )
    ),
    
    nav_panel("Model Performance",
      layout_columns(
        value_box(
          title = "AUC",
          value = textOutput("metric_auc"),
          theme = "secondary"
        ),
        value_box(
          title = "Accuracy",
          value = textOutput("metric_acc"),
          theme = "secondary"
        )
      ),
      layout_columns(
        card(
          card_header("ROC Curve"),
          plotlyOutput("roc_curve")
        ),
        card(
          card_header("Confusion Matrix"),
          plotlyOutput("conf_matrix")
        )
      )
    ),
    
    nav_panel("Customer Data",
      DTOutput("customer_table")
    )
  )
)

server <- function(input, output, session) {
  
  # Update inputs if an existing customer is selected
  observeEvent(input$customer_selector, {
    if(input$customer_selector != "new") {
      cust <- raw_data[raw_data$customer_id == input$customer_selector, ]
      updateNumericInput(session, "tenure_months", value = cust$tenure_months)
      updateSelectInput(session, "contract_type", selected = cust$contract_type)
      updateNumericInput(session, "monthly_charges", value = cust$monthly_charges)
      updateSelectInput(session, "internet_service", selected = cust$internet_service)
      updateSelectInput(session, "tech_support", selected = cust$tech_support)
      updateSelectInput(session, "payment_method", selected = cust$payment_method)
      updateSelectInput(session, "senior_citizen", selected = cust$senior_citizen)
      updateSelectInput(session, "partner", selected = cust$partner)
      updateSelectInput(session, "dependents", selected = cust$dependents)
    }
  })
  
  # Reactive prediction
  prediction <- eventReactive(input$predict_btn, {
    new_data <- data.frame(
      tenure_months = input$tenure_months,
      contract_type = input$contract_type,
      monthly_charges = input$monthly_charges,
      internet_service = input$internet_service,
      tech_support = input$tech_support,
      payment_method = input$payment_method,
      senior_citizen = input$senior_citizen,
      partner = input$partner,
      dependents = input$dependents,
      stringsAsFactors = FALSE
    )
    
    # Add dummy total_charges since model might expect it
    new_data$total_charges <- new_data$monthly_charges * new_data$tenure_months
    
    # Predict
    pred_prob <- predict(final_model, new_data, type = "prob")
    prob_yes <- pred_prob$.pred_Yes[1]
    
    list(
      prob = prob_yes,
      risk = if(prob_yes > 0.7) "High" else if (prob_yes > 0.3) "Medium" else "Low"
    )
  })
  
  output$prediction_result <- renderUI({
    req(prediction())
    res <- prediction()
    color <- switch(res$risk, "High" = "danger", "Medium" = "warning", "Low" = "success")
    
    div(
      class = paste0("alert alert-", color, " text-center"),
      h4("Risk Category: ", res$risk),
      p(sprintf("Probability: %.1f%%", res$prob * 100))
    )
  })
  
  output$gauge_chart <- renderPlotly({
    req(prediction())
    prob <- prediction()$prob * 100
    
    plot_ly(
      domain = list(x = c(0, 1), y = c(0, 1)),
      value = prob,
      title = list(text = "Churn Risk"),
      type = "indicator",
      mode = "gauge+number",
      gauge = list(
        axis = list(range = list(NULL, 100)),
        bar = list(color = "black"),
        steps = list(
          list(range = c(0, 30), color = "lightgreen"),
          list(range = c(30, 70), color = "lightyellow"),
          list(range = c(70, 100), color = "salmon")
        )
      )
    )
  })
  
  # Dashboard Charts
  output$overall_churn <- renderText({
    rate <- mean(raw_data$churn == "Yes")
    sprintf("%.1f%%", rate * 100)
  })
  
  output$contract_chart <- renderPlotly({
    df <- raw_data %>%
      group_by(contract_type) %>%
      summarise(ChurnRate = mean(churn == "Yes") * 100)
    
    plot_ly(df, x = ~contract_type, y = ~ChurnRate, type = 'bar', marker = list(color = 'steelblue')) %>%
      layout(yaxis = list(title = 'Churn Rate (%)'), xaxis = list(title = 'Contract Type'))
  })
  
  output$tenure_chart <- renderPlotly({
    df <- raw_data %>%
      mutate(tenure_bucket = cut(tenure_months, breaks = seq(0, 72, by = 12))) %>%
      group_by(tenure_bucket) %>%
      summarise(ChurnRate = mean(churn == "Yes") * 100, .groups = 'drop') %>%
      filter(!is.na(tenure_bucket))
    
    plot_ly(df, x = ~tenure_bucket, y = ~ChurnRate, type = 'scatter', mode = 'lines+markers',
            line = list(color = 'firebrick', width = 3)) %>%
      layout(yaxis = list(title = 'Churn Rate (%)'), xaxis = list(title = 'Tenure (Months)'))
  })
  
  output$importance_chart <- renderPlotly({
    # We can extract importance if the engine is randomForest
    # Note: extracting from tidymodels workflow needs specific steps
    model_obj <- extract_fit_parsnip(final_model)$fit
    if(inherits(model_obj, "randomForest")) {
      imp <- as.data.frame(model_obj$importance)
      imp$Feature <- rownames(imp)
      imp <- imp[order(imp$MeanDecreaseGini, decreasing = FALSE), ]
      plot_ly(imp, x = ~MeanDecreaseGini, y = ~factor(Feature, levels = Feature), type = 'bar', orientation = 'h') %>%
        layout(title = "Random Forest Feature Importance", xaxis = list(title = "Mean Decrease Gini"), yaxis = list(title = ""))
    } else {
      # Dummy plot if not random forest
      plot_ly(x = 1, y = 1, type = "scatter", mode = "text", text = "Feature importance not available for this model type")
    }
  })
  
  # Model Performance
  output$metric_auc <- renderText({
    auc_val <- roc_auc(test_preds, truth = churn, .pred_Yes)$.estimate
    sprintf("%.3f", auc_val)
  })
  
  output$metric_acc <- renderText({
    acc_val <- accuracy(test_preds, truth = churn, estimate = .pred_class)$.estimate
    sprintf("%.1f%%", acc_val * 100)
  })
  
  output$roc_curve <- renderPlotly({
    roc_data <- roc_curve(test_preds, truth = churn, .pred_Yes)
    plot_ly(roc_data, x = ~1 - specificity, y = ~sensitivity, type = 'scatter', mode = 'lines', line = list(color = "blue")) %>%
      add_segments(x = 0, y = 0, xend = 1, yend = 1, line = list(dash = "dash", color = "black"), showlegend = FALSE) %>%
      layout(xaxis = list(title = "False Positive Rate (1 - Specificity)"),
             yaxis = list(title = "True Positive Rate (Sensitivity)"))
  })
  
  output$conf_matrix <- renderPlotly({
    cm <- conf_mat(test_preds, truth = churn, estimate = .pred_class)$table
    plot_ly(x = colnames(cm), y = rownames(cm), z = as.matrix(cm), type = "heatmap", colors = "Blues") %>%
      layout(xaxis = list(title = "Predicted Class"), yaxis = list(title = "Actual Class", autorange = "reversed"))
  })
  
  # Data Table
  output$customer_table <- renderDT({
    datatable(raw_data, options = list(pageLength = 10, scrollX = TRUE), filter = 'top')
  })
}

shinyApp(ui, server)
