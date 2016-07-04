shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    #tags$head(includeScript("statcounter.js")),
    tags$script("$(document).ready(function() {
                    language=window.location.search.split('?queryid=')
                    $('#queryid').val(language)
                });"),
    tags$input(id = 'queryid', type = 'text', style = 'display:none;'),
    fluidRow(
      div(img(src="TEDbanner.png", height = 132, width = 1100), align="center")
    ),
    br(),
    hr(),
    uiOutput("quest"),
    hr(),
    a(strong("Get to know Tender better, play the lottery!"),href="http://supplier.tenders.exposed/",target="_blank"),
    tags$div(class="extraspace5"),
    tabsetPanel(
      tabPanel(h5(strong("TED Award Notices 2006-2015")),
               fluidRow(
                 shiny::column(11,offset=1,
                        fluidRow(
                          queryBuildROutput("queryBuilderWidget",width="900px",height="100%"),
                          actionButton("queryApply", label = "Apply filters"),
                          textOutput("filters"),
                          tags$script('
                                    function getSQLStatement() {
                                        var sql = $("#queryBuilderWidget").queryBuilder("getSQL", false);
                                        Shiny.onInputChange("queryBuilderSQL", sql);
                                    };
                                    document.getElementById("queryApply").onclick = function() {getSQLStatement()}
                                  '),
                          tags$script('            
                                      Shiny.addCustomMessageHandler("callbackHandlerQuery",  function(sqlQuery) {
                                           if (sqlQuery=="reset") $("#queryBuilderWidget").queryBuilder("reset")
                                           else $("#queryBuilderWidget").queryBuilder("setRulesFromSQL",sqlQuery);
                                      });
                                ')
                          
                        )
                 )
               ),
               shiny::column(12,
                      fluidRow(
                        hr(),
                        div(downloadButton('downloadSelection', label = "Download selection (CSV)",class = NULL),
                            align="right"),
                        uiOutput("showVarUI"),
                        DT::dataTableOutput('awardTable'),
                        h5(textOutput("nbRowsErrorMessage")),
                        tags$div(class="extraspace5")
                      )
               )
      ),
      tabPanel(h5(strong("Sankey diagram")),
               shiny::column(12,offset=0,
                      tags$div(class="extraspace5"),
                      uiOutput("sankeyUI"),
                      tags$div(class="extraspace5")
               )
      ),
      tabPanel(h5(strong("CPV codes")),
               shiny::column(10,offset=1,
                      fluidRow(
                        tags$div(class="extraspace5"),
                        h4(strong("Meanings of Common Procurement Vocabulary (CPV) codes")),
                        div(DT::dataTableOutput('CPVTable'),align="center"),
                        tags$div(class="extraspace5")
                      )
               )
               
      ),
      tabPanel(h5(strong("What is this interface?")),
               shiny::column(10,offset=1,
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

