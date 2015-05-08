library(shiny)
library(RMySQL)
requireNamespace('htmlwidgets')
library(DT)


sessionvalues <- reactiveValues()
con <- dbConnect(RSQLite::SQLite(), "../TED.db")
rs<-dbSendQuery(con,"select contract_doc_no,contract_contract_value_cost_eur,document_title_country,contract_operator_official_name,document_award_criteria,contract_cpv_code from contracts where contract_contract_value_cost_eur>0")
data = fetch(rs, n=-1)
data[,2]<-round(data[,2])
data<-cbind(data,"log10Award"=log10(data[,2]))
sessionvalues$data<-data               
dbDisconnect(con)

shinyServer(function(input, output) {
  
  observe({
    if (length(input$range)>0) {
      
      sessionvalues$data<-data[which((data[,"log10Award"]>input$range[1]) & (data[,"log10Award"]<input$range[2])),]
    }
  })
  
  output$awardValuePlot <- renderPlot({
    hist(sessionvalues$data[,'contract_contract_value_cost_eur'], 
         main="Histogram of award values",
         ylab="Number",
         xlab="Award values")
  })
  
  createName<-function(s) {
    paste0(s[2],'-',s[1])
  }
  
  output$awardTable<-DT::renderDataTable({
    data<-sessionvalues$data[,-7]
    colnames(data)<-c("Award notice ID","Award value (EUR)","Country","Contractor name","Award criteria","CPV code")
    #browser()
    namesDoc<-as.character(unlist(lapply(sapply(data[,1],strsplit,"/S (.*)-"),createName)))
    linkDoc<-paste0("<a href='http://ted.europa.eu/udl?uri=TED:NOTICE:",namesDoc,":TEXT:EN:HTML&src=0' target='_blank'>",namesDoc,'</a>')
    data[,1]<-linkDoc
    
    datatable(
      data,rownames=checkboxRows(data),escape= FALSE,
      ,options = list(
        dom='fltip', 
        lengthMenu = list(c(10, 25, -1), c('10', '25','All')),pageLength = 10,
        autoWidth = FALSE
        #columns.width = list(list(width = "200px", width = "200px",
        #                          width = "200px", width = "30px"))#, bFilter=F)
      )
    )
  }
  )
  
})
