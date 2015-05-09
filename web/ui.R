library(shiny)

shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    fluidRow(
      img(src="TEDbanner.png", height = 122, width = 1000)
    ),
    hr(),
    fluidRow(
      column(12,
             dateRangeInput('dateRange',
                            label = 'Select period to cover (yyyy-mm-dd)',
                            start = "2015-01-01", end = Sys.Date()
             ),
             hr(),
             h5("Note: Refreshing data takes on average 10 seconds for half a year of data (like 2015-01-01/2015-05-01 range). Data is available from 2012-01-01. Around one million records will be included from 2012-01-01. Refreshing pages may take up to 30 seconds."),
             hr(),
             tabsetPanel(
               tabPanel("Statistics per country",
                        h3("Total award notices per country"),
                        plotOutput('authorityCountryBarPlot'),
                        tags$div(class="extraspace2"),
                        h3("Total award value per country"),
                        plotOutput('valueCountryBarPlot'),
                        tags$div(class="extraspace2")
               ),
               tabPanel("Award notices", 
                        selectInput("selectAuthorityCountry", label = h3("Contract authority country"), 
                                    choices = countries, 
                                    selected = "All"),
                        hr(),
                        dataTableOutput('awardTable'),
                        tags$style(type="text/css", 'tfoot {display:table-header-group;}')
               )
             ),
             tags$div(class="extraspace")
      )
    )
  )
)