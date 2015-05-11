library(shiny)
source("chooser.R")

shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    fluidRow(
      img(src="TEDbanner.png", height = 122, width = 1000)
    ),
    hr(),
    fluidRow(
      column(12,
             tabsetPanel(
               tabPanel("Award notices 2012/2015", 
                        column(12,
                               checkboxInput("filters", label = "Show advanced selectors", value = F),
                               conditionalPanel(
                                 condition = "input.filters== 1",
                                 fluidRow(column(6,
                                                 fluidRow(
                                                   dateRangeInput('dateRange',
                                                                  label = h5(strong('Select period to cover (yyyy-mm-dd)')),
                                                                  start = "2015-01-01", end = "2015-02-28"
                                                   )
                                                 ),
                                                 fluidRow(
                                                   selectInput("selectAuthorityCountry", label = h5(strong("Contract authority country")), 
                                                               choices = authority_countries, 
                                                               selected = "All"
                                                   )
                                                 ),
                                                 fluidRow(
                                                   selectInput("selectOperatorCountry", label = h5(strong("Contract operator country")), 
                                                               choices = operator_countries, 
                                                               selected = "All"
                                                   )
                                                 ),
                                                 fluidRow(
                                                   selectInput("select CPV code", label = h5(strong("CPV code")), 
                                                               choices = CPV_code, 
                                                               selected = "UK"
                                                   )
                                                 )
                                 ),
                                 column(6,
                                        fluidRow(
                                          tags$div(class="extraspace3"),
                                          chooserInput("fields", "Available fields", "Selected fields",
                                                       setdiff(names(nameFields),defaultFieldsDisplay), defaultFieldsDisplay, size = 10, multiple = TRUE
                                          )  
                                        )
                                 )),
                                 fluidRow(
                                   actionButton("applySelection","Apply selection"),
                                   align="center"
                                 )
                               ),
                               hr(),
                               h3(strong("Award notices")),
                               hr(),
                               downloadButton('outputId', label = "Download CSV", class = NULL),
                               downloadButton('outputId2', label = "Download CSV for Gephi", class = NULL),
                               hr(),
                               dataTableOutput('awardTable'),
                               tags$style(type="text/css", 'tfoot {display:none;}')
                        )
               ),
               tabPanel("About",
                        h3("Total award notices per country"),
                        #plotOutput('authorityCountryBarPlot'),
                        tags$div(class="extraspace2"),
                        h3("Total award value per country"),
                        #plotOutput('valueCountryBarPlot'),
                        tags$div(class="extraspace2")
               )
             )
      )
    ),
    tags$div(class="extraspace")
  )
)