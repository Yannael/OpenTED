library(shiny)
library(markdown)
source("chooser.R")
library(DT)

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
                        
                        dateRangeInput('dateRange',
                                       label = h5(strong('Select period to cover (yyyy-mm-dd)')),
                                       start = "2015-01-01", end = "2015-02-28"
                        ),
                        downloadButton('downloadAwards', label = "Download CSV", class = NULL),
                        #downloadButton('downloadAwardsGephi', label = "Download CSV for Gephi", class = NULL),
                        hr(),
                        div(style = 'overflow-x: scroll;',DT::dataTableOutput('awardTable')),
                        tags$style(type="text/css", 'thead {height:100px;}'),
                        tags$style(type="text/css", '.dataTables_scroll {overflow:visible;}'),
                        tags$div(class="extraspace")
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

