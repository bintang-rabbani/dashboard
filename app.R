# Load libraries
library(shiny)
library(shinydashboard)
library(DBI)
library(RPostgres)
library(tidyverse)
library(plotly)
library(DT)
library(viridis)
library(dashboardthemes)

# Disable scientific notation
options(scipen = 999)

# DB connect function
db_connect <- function() {
  dbConnect(
    Postgres(),
    dbname   = Sys.getenv("DB_NAME", "railway"),
    host     = Sys.getenv("DB_HOST", "nozomi.proxy.rlwy.net"),
    port     = as.integer(Sys.getenv("DB_PORT", 49571)),
    user     = Sys.getenv("DB_USER", "postgres"),
    password = Sys.getenv("DB_PASSWORD", "ZJvdaWwtZBzHSDnUglLzwsUwWjdahEip")
  )
}

# Dashboardthemes:
# "grey_dark", "grey_light", "blue_gradient", "purple_gradient", "flat_red"
selected_theme <- "blue_gradient"

# UI
ui <- dashboardPage(
  skin = "blue",
  title = "Dashboard",
  header = dashboardHeader(
    title = span(style = "font-family: 'Roboto', sans-serif; font-weight: bold; color: #fff;", "Go Sales"),
    titleWidth = 280
  ),
  dashboardSidebar(
    width = 280,
    tags$head(
      tags$style(HTML(
        "
        body.sidebar-collapse .main-sidebar .form-group { display: none !important; }
        .main-sidebar .form-group .selectize-control { width: 100% !important; }
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #4e79a7, #1f3b73);
        }
        .skin-blue .sidebar a {
          color: #fff;
        }
        .skin-blue .sidebar a:hover {
          color: #e0e7ff;
        }
        .skin-blue .main-header .navbar, .skin-blue .main-header .logo {
          background: linear-gradient(180deg, #1f3b73, #16325c);
        }
        .box, .small-box {
          border-radius: 8px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .dataTables_wrapper .dataTables_filter input {
          border-radius: 4px;
          border: 1px solid #ccc;
        }
        "
      )),
      tags$script(HTML(
        "
        $(document).on('click', '.sidebar-toggle', function() {
          var collapsed = $('body').hasClass('sidebar-collapse');
          Shiny.setInputValue('sidebar_collapsed', collapsed, {priority: 'event'});
        });
        "
      ))
    ),
    shinyDashboardThemes(
      theme = selected_theme
    ),
    sidebarMenu(
      menuItem("Data", tabName = "data", icon = icon("table")),
      menuItem("Summary", tabName = "summary", icon = icon("chart-pie")),
      menuItem("Category", tabName = "category", icon = icon("th-list")),
      menuItem("Product Type", tabName = "type", icon = icon("box-open")),
      menuItem("Brand", tabName = "brand", icon = icon("tags"))
    ),
    hr(style = "border-color: #b3cde0;"),
    selectInput("catSelect", "Select category:", choices = NULL),
    selectInput("typeSelect", "Select type:", choices = NULL),
    selectInput("brandSelect", "Select brand:", choices = NULL)
  ),
  dashboardBody(
    fluidPage(
      tags$head(
        tags$link(rel = "shortcut icon", href = "favicon.ico", type = "image/x-icon"),
        tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Roboto:400,700&display=swap")
      ),
      tabItems(
        tabItem(tabName = "summary",
                fluidRow(
                  valueBoxOutput("boxRevenue", width = 4),
                  valueBoxOutput("boxQuantity", width = 4),
                  valueBoxOutput("boxMarkup", width = 4)
                ),
                fluidRow(
                  box(title = "Average Price per Category", width = 12, solidHeader = TRUE, status = "primary", plotlyOutput("plotAvgPriceCat", height = 300)),
                  box(title = "Quantity Sold per Category", width = 12, solidHeader = TRUE, status = "success", plotlyOutput("plotCategoryquantity", height = 300))
                )
        ),
        tabItem(tabName = "category",
                fluidRow(
                  box(title = "Product per Category", width = 12, solidHeader = TRUE, status = "warning", plotlyOutput("plotProductsPerCat", height = 400))
                )
        ),
        tabItem(tabName = "type",
                fluidRow(
                  box(title = "Revenue by Product Type", width = 12, solidHeader = TRUE, status = "success", plotlyOutput("plotTypeDetail", height = 400))
                )
        ),
        tabItem(tabName = "brand",
                fluidRow(
                  box(title = "Top 10 Brands by Units Sold", width = 12, solidHeader = TRUE, status = "danger", plotlyOutput("plotTopBrandsquantity", height = 350)),
                  box(title = "Unique Products per Brand", width = 12, solidHeader = TRUE, status = "primary", plotlyOutput("plotUniqueProdBrand", height = 350))
                )
        ),
        tabItem(tabName = "data",
                fluidRow(
                  box(title = "Products Dataset", width = 12, solidHeader = TRUE, status = "info", DTOutput("tableData"))
                )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  data_all <- reactive({
    con <- db_connect()
    on.exit(dbDisconnect(con), add = TRUE)
    dbGetQuery(con, "SELECT * FROM products")
  })
  
  observe({
    df <- data_all()
    updateSelectInput(session, "catSelect", choices = c("All", unique(df$product_category)), selected = "All")
    updateSelectInput(session, "typeSelect", choices = c("All", unique(df$product_type)), selected = "All")
    updateSelectInput(session, "brandSelect", choices = c("All", unique(df$product_brand)), selected = "All")
  })
  
  filtered <- reactive({
    df <- data_all()
    if (!is.null(input$catSelect) && input$catSelect != "All") df <- filter(df, product_category == input$catSelect)
    if (!is.null(input$typeSelect) && input$typeSelect != "All") df <- filter(df, product_type == input$typeSelect)
    if (!is.null(input$brandSelect) && input$brandSelect != "All") df <- filter(df, product_brand == input$brandSelect)
    df
  })
  
  output$boxRevenue <- renderValueBox({
    rev <- sum(filtered()$revenue, na.rm = TRUE)
    valueBox(scales::dollar(rev), "Total Revenue", icon = icon("shopping-cart"), color = "light-blue")
  })
  output$boxQuantity <- renderValueBox({
    quantity <- sum(filtered()$quantity, na.rm = TRUE)
    valueBox(quantity, "Total Quantity", icon = icon("boxes"), color = "yellow")
  })
  output$boxMarkup <- renderValueBox({
    mpu <- mean(filtered()$markup, na.rm = TRUE)
    valueBox(round(mpu, 2), "Average Markup", icon = icon("line-chart"), color = "maroon")
  })
  
  base_theme <- theme_minimal() + theme(axis.title = element_blank())
  
  output$plotAvgPriceCat <- renderPlotly({
    dat <- filtered() %>% group_by(product_category) %>% summarize(average_price = sum(revenue, na.rm=TRUE)/sum(quantity, na.rm=TRUE))
    p <- ggplot(dat, aes(reorder(product_category, average_price), average_price,
                         text = paste0(product_category, ': $', round(average_price, 2)))) +
      geom_col(aes(fill = average_price)) + scale_fill_viridis(option = "viridis") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$plotCategoryquantity <- renderPlotly({
    dat <- filtered() %>% group_by(product_category) %>% summarize(quantity = sum(quantity, na.rm=TRUE))
    p <- ggplot(dat, aes(reorder(product_category, quantity), quantity,
                         text = paste0(product_category, ': ', quantity, ' units'))) +
      geom_col(aes(fill = quantity)) + scale_fill_viridis(option = "viridis") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$plotProductsPerCat <- renderPlotly({
    dat <- filtered() %>% group_by(product_category) %>% summarize(count = n_distinct(product_id))
    p <- ggplot(dat, aes(reorder(product_category, count), count,
                         text = paste0(product_category, ': ', count, ' products'))) +
      geom_col(aes(fill = count)) + scale_fill_viridis(option = "cividis") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$plotTypeDetail <- renderPlotly({
    dat <- filtered() %>% group_by(product_type) %>% summarize(revenue = sum(revenue, na.rm=TRUE))
    p <- ggplot(dat, aes(product_type, revenue,
                         text = paste0(product_type, ': $', scales::comma(revenue)))) +
      geom_col(aes(fill = revenue)) + scale_fill_viridis(option = "plasma") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$plotTopBrandsquantity <- renderPlotly({
    dat <- filtered() %>% group_by(product_brand) %>% summarize(quantity = sum(quantity, na.rm=TRUE)) %>% slice_max(quantity, n = 10)
    p <- ggplot(dat, aes(reorder(product_brand, quantity), quantity,
                         text = paste0(product_brand, ': ', quantity, ' units'))) +
      geom_col(aes(fill = quantity)) + scale_fill_viridis(option = "turbo") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$plotUniqueProdBrand <- renderPlotly({
    dat <- filtered() %>% group_by(product_brand) %>% summarize(unique_count = n_distinct(product_id)) %>% slice_max(unique_count, n = 10)
    p <- ggplot(dat, aes(reorder(product_brand, unique_count), unique_count,
                         text = paste0(product_brand, ': ', unique_count, ' products'))) +
      geom_col(aes(fill = unique_count)) + scale_fill_viridis(option = "turbo") + coord_flip() + base_theme
    ggplotly(p, tooltip = "text")
  })
  
  output$tableData <- renderDT({
    datatable(filtered(), options = list(pageLength = 10, scrollX = TRUE))
  })
}

# Run app
shinyApp(ui, server)
