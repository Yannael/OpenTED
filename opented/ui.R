library(shiny)
library(markdown)
library(DT)

shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    tags$head(includeScript("analytics.js")),
    fluidRow(
      img(src="TEDbanner.png", height = 122, width = 1000)
    ),
    br(),
    hr(),
    fluidRow(
      column(12,
             tabsetPanel(
               tabPanel(h5(strong("TED Award Notices 2012/2015")), 
                        column(12,
                               checkboxInput("filters", label = "Show filtering options", value = F),
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
                                                 )
                                 ),
                                 column(6,
                                        fluidRow(
                                          column(6,
                                                 textInput("CPVFrom",label = h5(strong("CPV code from")), 
                                                           value = "")),
                                          column(2,
                                                 textInput("CPVTo",label = h5(strong("to")), 
                                                           value = ""))
                                        ),
                                        fluidRow(
                                          column(6,
                                                 textInput("valueFrom",label = h5(strong("Contract value from")), 
                                                           value = "")),
                                          column(2,
                                                 textInput("valueTo",label = h5(strong("to")), 
                                                           value = ""))
                                          
                                        ),
                                        fluidRow(
                                          column(6,
                                                 textInput("nbOffersFrom",label = h5(strong("Number of offers from")), 
                                                           value = "")),
                                          column(2,
                                                 textInput("nbOffersTo",label = h5(strong("to")), 
                                                           value = ""))
                                          
                                        )
                                 )
                                 ),
                                 fluidRow(
                                   actionButton("applySelection","Apply selection",class="btn btn-primary"),
                                   align="center"
                                 ),
                                 br(),
                                 fluidRow(
                                   textOutput("nbRowsErrorMessage"),
                                   align="center"
                                 )
                               ),
                               DT::dataTableOutput('awardTable'),
                               tags$div(class="extraspace5"),
                               downloadButton('downloadAwards', label = "Download CSV", class = NULL)
                               #downloadButton('downloadAwardsGephi', label = "Download GEXF (Gephi)", class = NULL)
                        )
               ),
               tabPanel(h5(strong("About")),
                        tags$div(class="extraspace5"),
                        includeMarkdown("README.md")
               )
             )
      )
    ),
    tags$div(class="extraspace")
  )
)

