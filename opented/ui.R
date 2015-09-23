library(shiny)
library(queryBuildR)
library(markdown)
library(DT)
library(networkD3)

shinyUI(
  fluidPage(    
    includeCSS('www/style.css'),
    tags$head(includeScript("statcounter.js")),
    #tags$head(HTML('<meta property="og:image" content="http://litpc45.ulb.ac.be/lyricsexplorer.png">')),
    #tags$head(HTML('<meta property="og:title" content="Lyrics Explorer">')),
    #tags$head(HTML('<meta property="og:url" content="http://yleborgne.net/opented">')),
    tags$head(HTML('<meta property="fb:admins" content="yannael.leborgne">')),
    tags$script("$(document).ready(function() {
                    language=window.location.search.split('?queryid=')
                    $('#queryid').val(language)
                });"),
    tags$input(id = 'queryid', type = 'text', style = 'display:none;'),
    HTML("<div id='fb-root'></div>
<script>(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = '//connect.facebook.net/en_US/sdk.js#xfbml=1&version=v2.4';
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));</script>"),
    fluidRow(
      div(img(src="TEDbanner.png", height = 132, width = 1100), align="center")
    ),
    br(),
    hr(),
    uiOutput("quest"),
    hr(),
    tabsetPanel(
      tabPanel(h5(strong("TED Award Notices 2012/2015")),
               fluidRow(
                 column(11,offset=1,
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
               column(12,
                      fluidRow(
                        hr(),
                        div(downloadButton('downloadSelection', label = "Download selection (CSV)",class = NULL),
                            align="right"),
                        DT::dataTableOutput('awardTable'),
                        h5(textOutput("nbRowsErrorMessage")),
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
                        div(DT::dataTableOutput('CPVTable'),align="center"),
                        tags$div(class="extraspace5")
                      )
               )
               
      ),
      tabPanel(h5(strong("What is this interface?")),
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

