library(shiny)
library(queryBuildR)
library(markdown)
library(DT)
library(networkD3)

shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    #tags$head(includeScript("statcounter.js")),
    fluidRow(
      div(img(src="TEDbanner.png", height = 132, width = 1100), align="center")
    ),
    br(),
    hr(),
    tabsetPanel(
      tabPanel(h5(strong("TED Award Notices 2012/2015")),
               fluidRow(
                 column(11,offset=1,
                        fluidRow(
                          queryBuildROutput("queryBuilderWidget",width="900px",height="100%"),
                          actionButton("queryApply", label = "Apply filters"),
                          tags$script('
                                    function getSQLStatement() {
                                        var sql = $("#queryBuilderWidget").queryBuilder("getSQL", false);
                                        Shiny.onInputChange("queryBuilderSQL", sql);
                                    };
                                    document.getElementById("queryApply").onclick = function() {getSQLStatement()}
                                  ')
                        )
                 )
               ),
               column(12,
                      fluidRow(
                        hr(),
                        h5(textOutput("nbRowsErrorMessage")),
                        div(downloadButton('downloadSelection', label = "Download selection (CSV)",class = NULL),
                            align="right"),
                        DT::dataTableOutput('awardTable'),
                        tags$div(class="extraspace5")
                      )
               )
      ),
      tabPanel(h5(strong("Contract flows")),
               column(10,offset=1,
                      tags$div(class="extraspace5"),
                      uiOutput("sankeyUI"),
                      tags$div(class="extraspace5")
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
      tabPanel(h5(strong("What is this?")),
               column(10,offset=1,
                      fluidRow(
                        tags$div(class="extraspace5"),
                        includeMarkdown("README.md")
                      )
               )
      )
    ),
    tags$div(class="extraspace")
  )
)

