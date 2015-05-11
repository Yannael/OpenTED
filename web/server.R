library(shiny)
library(RMySQL)
library(ggplot2)

shinyServer(function(input, output) {
  
  sessionData <- reactiveValues()
  
  #Modify range of session data to display according to date range
  updateAwardsNotice<-function(selectAuthorityCountry, dateRange, fields) {
    if (selectAuthorityCountry!="All") country_select<-paste0(" and contract_authority_country='",input$selectAuthorityCountry,"' ")
    else country_select<-""
    fields<-nameFields[match(fields,names(nameFields))]
    con <- dbConnect(RSQLite::SQLite(), "../TED_award_notices.db")
    rs<-dbSendQuery(con,paste0("select ", paste(fields,collapse=",")," 
                                   from contracts 
                                   where 
                                   document_oj_date>'",dateRange[1],"' ", 
                                   "and document_oj_date<'",dateRange[2],"' ",
                                   #"and contract_contract_value_cost_eur>0 ",
                                   country_select,
                                   " ORDER BY document_oj_date ASC
                                   "))
    awardNotices = fetch(rs, n=-1)
    dbClearResult(rs)
    dbDisconnect(con) 
    colnames(awardNotices)<-names(nameFields)[match(fields,nameFields)]
    awardNotices
  }
  
  observe({
    input$applySelection
    isolate({
    if (length(input$dateRange)>0 & (length(input$selectAuthorityCountry)>0) & (length(input$fields$right)>0)) {
      sessionData$data<-updateAwardsNotice(input$selectAuthorityCountry,input$dateRange,input$fields$right)
    }
    })
  })
  
  #Returns a bar plot with the number of award notices per contract authority country
  output$authorityCountryBarPlot<-renderPlot({
    data<-sessionData$data
    uniqueAuthorityContract<-unique(data[,c('contract_doc_no','contract_authority_country')])
    plot_return<-ggplot(uniqueAuthorityContract, aes(factor(contract_authority_country)))+
      geom_bar()+coord_flip()+
      xlab("Country")+
      ylab("Number of award notices")
    plot_return
  }, height = 800, width = 900)
  
  #Returns a bar plot with the total value of awards (in Euro) per contract authority country
  output$valueCountryBarPlot<-renderPlot({
    data<-sessionData$data
    plot_return<-ggplot(data,aes(contract_authority_country,y=contract_contract_value_cost_eur))+
      geom_bar(stat="identity")+coord_flip()+
      xlab("Country")+
      ylab("Total value of awards")
    plot_return
  }, height = 800, width = 900)
  
  #Returns the dataset in the form of a table, filtered by country
  output$awardTable<-renderDataTable({
    sessionData$data
  },
  escape=F,#This so HTML links are properly rendered
  options=list(
    lengthMenu = list(c(10, 100, -1), c('10', '100','All')),pageLength = 10,search=list(regex=T),
    autoWidth = T,aoColumnDefs = list(list(sClass="alignRight",aTargets="_all"))
  )
  )
  
})
