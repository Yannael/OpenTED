library(shiny)
library(RMySQL)
library(ggplot2)

shinyServer(function(input, output) {
  
  sessionData <- reactiveValues()
  
  #Modify award notices to display according to date/country/CPV/fields selectors
  updateAwardsNotice<-function(authorityCountry, operatorCountry, dateRange, fields, CPVcode) {
    if (authorityCountry!="All") country_select_authority<-paste0(" and contract_authority_country='",authorityCountry,"' ")
    else country_select_authority<-""
    if (operatorCountry!="All") country_select_operator<-paste0(" and contract_operator_country='",operatorCountry,"' ")
    else country_select_operator<-""
    if (CPVcode!="All") CPV_code_select<-paste0(" and contract_cpv_code='",CPVcode,"' ")
    else CPV_code_select<-""
    fields<-nameFields[match(fields,names(nameFields))]
    con <- dbConnect(RSQLite::SQLite(), "../TED_award_notices.db")
    rs<-dbSendQuery(con,paste0("select ", paste(fields,collapse=",")," 
                                   from contracts 
                                   where 
                                   document_oj_date>'",dateRange[1],"' ", 
                                   "and document_oj_date<'",dateRange[2],"' ",
                                   country_select_authority,
                                   country_select_operator,
                                   CPV_code_select,
                                   " ORDER BY document_oj_date ASC
                                   "))
    awardNotices = fetch(rs, n=-1)
    dbClearResult(rs)
    dbDisconnect(con) 
    colnames(awardNotices)<-names(nameFields)[match(fields,nameFields)]
    awardNotices
  }
  
  #Update award notices when apply button pushed
  observe({
    input$applySelection
    isolate({
    if (length(input$dateRange)>0 & (length(input$selectAuthorityCountry)>0) & (length(input$fields$left)>0) & (length(input$selectCPVcode)>0)) {
      sessionData$data<-updateAwardsNotice(input$selectAuthorityCountry,input$selectOperatorCountry,input$dateRange,input$fields$left, input$selectCPVcode)
    }
    })
  })
  
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
  
  output$downloadAwards <- downloadHandler(
       filename = function() {
         paste('data-', Sys.Date(), '.csv', sep='')
       },
       content = function(con) {
         write.csv(sessionData$data, con, row.names=F)
       }
     )
  
})
