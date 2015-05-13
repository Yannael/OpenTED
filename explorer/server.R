library(shiny)
library(RMySQL)
library(DT)

shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  
  #Modify award notices to display according to date/country/CPV/fields selectors
  updateAwardsNotice<-function(dateRange) {
    fields<-nameFields[1:13]
    con <- dbConnect(RSQLite::SQLite(), "data/TED_award_notices.db")
    rs<-dbSendQuery(con,paste0("select ", paste(fields,collapse=",")," 
                                from contracts 
                                where 
                                document_oj_date>'",dateRange[1],"' ", 
                               "and document_oj_date<'",dateRange[2],"' ",
                               "ORDER BY document_oj_date ASC
                               "))
    awardNotices = fetch(rs, n=-1)
    dbClearResult(rs)
    dbDisconnect(con) 
    colnames(awardNotices)<-names(nameFields)[match(fields,nameFields)]
    awardNotices
  }
  
  #Update award notices when date range is changed
  observe({
      if (length(input$dateRange)>0) 
        sessionData$data<-updateAwardsNotice(input$dateRange)
    })
  
  #Returns the dataset in the form of a table, filtered by country
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$data
    action = dataTableAjax(session, data)
    widget = datatable(data, 
                       server = TRUE, 
                       extensions = c('ColVis','Scroller','TableTools'),
                       escape=F,
                       filter = 'top',
                       options = list(
                         dom= 'T<"clear">CrtSi',
                         scrollX = TRUE,
                         deferRender = TRUE,
                         scrollY = 500,
                         scrollCollapse = T,
                         ajax = list(url = action),
                         tableTools = list(sSwfPath = copySWF()),
                         colVis=list(exclude=c(0)),
                         autoWidth = T,
                         columnDefs = list(list(className="dt-right",targets="_all"), 
                                           list(visible=F,targets=c(0,3,6,7,12)), 
                                           list(width='130px',targets="_all"),
                                           list(targets = c(1:9,12), searchable = TRUE),
                                           list(
                                             targets = c(3,5,6,7,9),
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
  })
  
  output$downloadAwards <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      browser()
      data<-input$awardTable_rows_all
      write.csv(data, con, row.names=F)
    }
  )
  
})
