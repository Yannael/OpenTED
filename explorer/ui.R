library(shiny)
library(markdown)
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
                                                   selectInput("selectCPVcode", label = h5(strong("CPV code")), 
                                                               choices = CPV_code, 
                                                               selected = "UK"
                                                   )
                                                 )
                                 ),
                                 column(6,
                                        fluidRow(
                                          #tags$div(class="extraspace3"),
                                          h5(strong("Select columns to display")),
                                          chooserInput("fields", "Selected fields", "Unselected fields",
                                                       defaultFieldsDisplay, setdiff(names(nameFields),defaultFieldsDisplay), 
                                                       size = 13, multiple = TRUE
                                          )  
                                        )
                                 )),
                                 fluidRow(
                                   actionButton("applySelection","Apply selection",class="btn btn-primary"),
                                   align="center"
                                 )
                               ),
                               hr(),
                               h3(strong("Award notices")),
                               hr(),
                               downloadButton('downloadAwards', label = "Download CSV", class = NULL),
                               downloadButton('downloadAwardsGephi', label = "Download CSV for Gephi", class = NULL),
                               hr(),
                               dataTableOutput('awardTable'),
                               tags$style(type="text/css", 'tfoot {display:none;}')
                        )
               ),
               tabPanel("About",
                        tags$div(class="extraspace5"),
                        includeMarkdown("README.md")
               )
             )
      )
    ),
    tags$div(class="extraspace")
  )
)

