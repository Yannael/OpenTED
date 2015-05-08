library(shiny)

shinyUI(
  fluidPage(    
    titlePanel("TED Explorer"),
    sidebarLayout(      
      sidebarPanel(
        sliderInput("range", "Range of award value (Logarithmic):",
                    min = 0, max = 10, value = c(8,10),round=-2),
        hr()
      ),
      mainPanel(
        plotOutput("awardValuePlot"),
        hr(),
        dataTableOutput('awardTable')
      )
      
    )
  )
)