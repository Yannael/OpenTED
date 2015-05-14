library(shiny)
library(RMySQL)
library(DT)
library(RCurl)

shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  sessionData$nbRowsErrorMessage<-""
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  #Modify award notices according to date/countries/CPV/value/offers filters
  updateAwardsNotice<-function(checkNbRows,authorityCountry, operatorCountry, dateRange, CPVFrom, CPVTo, valueFrom, valueTo, nbOffersFrom, nbOffersTo) {
    if (checkNbRows) 
      fields<-'count(1)'
    else fields<-paste(nameFields[1:13],collapse=",")
    
    tryCatch(getURL(paste("http://litpc45.ulb.ac.be/opented",authorityCountry,operatorCountry,dateRange[1],dateRange[2],CPVFrom,CPVTo,valueFrom,valueTo,nbOffersFrom,nbOffersTo,collapse="",sep="_")),error=function(cond) {})
    
    if (authorityCountry!="All") country_select_authority<-paste0(" and contract_authority_country='",authorityCountry,"' ")
    else country_select_authority<-""
    if (operatorCountry!="All") country_select_operator<-paste0(" and contract_operator_country='",operatorCountry,"' ")
    else country_select_operator<-""
    CPV<-""
    if ((CPVFrom!="") & (CPVTo != "")) CPV<-paste0(" and contract_cpv_code>=",CPVFrom," and contract_cpv_code<=",CPVTo)
    value<-""
    if ((valueFrom!="") & (valueTo != "")) value<-paste0(" and contract_contract_value_cost_eur>=",valueFrom," and contract_contract_value_cost_eur<=",valueTo)
    nbOffers<-""
    if ((nbOffersFrom!="") & (nbOffersTo != "")) nbOffers<-paste0(" and contract_offers_received_num>=",nbOffersFrom," and contract_offers_received_num<=",nbOffersTo)
    con <- dbConnect(RSQLite::SQLite(), "data/TED_award_notices.db")
    rs<-dbSendQuery(con,paste0("select ", fields," 
                                   from contracts 
                                   where 
                                   document_oj_date>='",dateRange[1],"' ", 
                               "and document_oj_date<='",dateRange[2],"' ",
                               country_select_authority,
                               country_select_operator,
                               CPV,
                               value,
                               nbOffers,
                               " ORDER BY document_oj_date ASC"
    ))
    results = fetch(rs, n=-1)
    dbClearResult(rs)
    dbDisconnect(con) 
    results
  }
  
  #Update award notices when apply button pushed
  observe({
    input$applySelection
    withProgress(min=1, max=3, expr={
      setProgress(message = 'Retrieving data, please wait...',
                  value=1)
      
      isolate({
        result<-updateAwardsNotice(T,input$selectAuthorityCountry,input$selectOperatorCountry,input$dateRange, input$CPVFrom, input$CPVTo, input$valueFrom, input$valueTo, input$nbOffersFrom, input$nbOffersTo)
      })
      
      setProgress(message = 'Retrieving data, please wait...',
                  value=2)
      
      if (result>500000) 
        sessionData$nbRowsErrorMessage<-paste0("Size limit exceeded: Current filters include ",result, " notices, the maximum is 500000.")
      else {
        isolate({
          awardNotices<-updateAwardsNotice(F,input$selectAuthorityCountry,input$selectOperatorCountry,input$dateRange, input$CPVFrom, input$CPVTo, input$valueFrom, input$valueTo, input$nbOffersFrom, input$nbOffersTo)
        })
        colnames(awardNotices)<-names(nameFields)
        sessionData$data<-awardNotices
        sessionData$nbRowsErrorMessage<-""
      }
      
      setProgress(message = 'Retrieving data, please wait...',
                  value=3)
      
      
    })
  })
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$data
    if (!is.null(dim(data))) {
      action = dataTableAjax(session, data)
      widget = datatable(data, 
                         server = TRUE, 
                         extensions = c('ColVis','Scroller'),
                         escape=F,
                         #filter = 'top',
                         options = list(
                           dom= 'CrtSi',
                           scrollX = TRUE,
                           deferRender = TRUE,
                           scrollY = 500,
                           scrollCollapse = T,
                           ajax = list(url = action),
                           colVis=list(exclude=c(0)),
                           autoWidth = T,
                           columnDefs = list(list(className="dt-right",targets="_all"), 
                                             list(visible=F,targets=c(0,3,6,9,12)), 
                                             list(width='130px',targets="_all"),
                                             #list(targets = c(1:9,12), searchable = TRUE),
                                             list(
                                               targets = c(3,5,6,8,9),
                                               render = JS(
                                                 "function(data, type, row, meta) {",
                                                 "return type === 'display' && data.length > 15 ?",
                                                 "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
                                                 "}")
                                             )
                           )
                         )
      )
      widget
    }
  })
  
  output$downloadAwards <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(sessionData$data, con, row.names=F)
    }
  )
  
})
