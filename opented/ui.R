library(shiny)
library(markdown)
library(DT)
library(networkD3)


shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    tags$head(includeScript("analytics.js")),
    fluidRow(
      div(img(src="TEDbanner.png", height = 152, width = 1300), align="center")
    ),
    br(),
    hr(),
    fluidRow(
      column(12,
             tabsetPanel(
               tabPanel(h5(strong("TED Award Notices 2012/2015")), 
                        column(12,
                               fluidRow(
                                 dateRangeInput('dateRange',
                                                label = h5(strong('Select period to cover (yyyy-mm-dd)')),
                                                start = "2015-02-01", end = "2015-02-28"
                                 )
                               ),
                               fluidRow(
                                 div(actionButton("applySelection","Apply",class="btn btn-primary"),
                                     align="left"),
                                 hr(),
                                 div(downloadButton('downloadSelection', label = "Download selection (CSV)",class = NULL),
                                     align="right")
                               ),
                               fluidRow(
                                 DT::dataTableOutput('awardTable'),
                                 tags$div(class="extraspace5")
                               )
                        )
               ),
                tabPanel(h5(strong("Contract flows")),
                         column(10,offset=1,
                         tags$div(class="extraspace5"),
                         uiOutput("sankeyUI")
                         )
                ),
               tabPanel(h5(strong("CPV codes")),
                        column(10,offset=1,
                               fluidRow(
                                 tags$div(class="extraspace5"),
                                 h4(strong("Meanings of Common Procurement Vocabulary (CPV) codes")),
                                 div(DT::dataTableOutput('CPVTable'),align="center")
                                 )
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

