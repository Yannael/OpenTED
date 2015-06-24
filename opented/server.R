library(shiny)
library(RMySQL)
library(DT)
library(RCurl)
library(networkD3)
library(rgexf)

source("myDT.R")

shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  sessionData$nbRowsErrorMessage<-""
  sessionData$heightSankey<-12500
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  #Modify award notices according to date/countries/CPV/value/offers filters
  updateAwardsNotice<-function(checkNbRows,dateRange) {
    if (checkNbRows) 
      fields<-'count(1)'
    else fields<-paste(nameFields,collapse=",")
    
    con <- dbConnect(RSQLite::SQLite(), "data/TED_award_notices.db")
    rs<-dbSendQuery(con,paste0("select ", fields," 
                                   from contracts 
                                   where 
                                   document_oj_date>='",dateRange[1],"' ", 
                               "and document_oj_date<='",dateRange[2],"' ",
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
        result<-updateAwardsNotice(T,input$dateRange)
      })
      
      setProgress(message = 'Retrieving data, please wait...',
                  value=2)
      
      isolate({
        awardNotices<-updateAwardsNotice(F,input$dateRange)
      })
      colnames(awardNotices)<-names(nameFields)
      sessionData$data<-awardNotices
      sessionData$currentData<-awardNotices
      sessionData$nbRowsErrorMessage<-""
      
      setProgress(message = 'Retrieving data, please wait...',
                  value=3)
      
      
    })
  })
  
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$data[,c(1,2,4,5,7,8,14,15,13)]
    data[,3]<-as.factor(data[,3])
    data[,5]<-as.factor(data[,5])
    data[,7]<-factor(data[,7],levels=c("NA","1-1K","1K-10K","10K-100K","100K-1M","1M-10M",">10M"))
    data[,8]<-factor(data[,8],levels=c("NA","1","2","3","4","5","6",">6"))
    data[,9]<-as.factor(data[,9])
    #browser()
    if (!is.null(dim(data))) {
      action = mydataTableAjax(session, data,sessionData=sessionData)
      widget = datatable(data, 
                         server = TRUE, 
                         escape=F,
                         filter = 'top',
                         options = list(
                           dom= 'iptlpi',
                           ajax = list(url = action),
                           lengthMenu = list(c(10, 100, 1000, 10000), c('10', '100','1000','10000')),pageLength = 10,
                           autoWidth = F,
                           #                                              list(
                           #                                                targets = c(3,5,6,8,9),
                           #                                                render = JS(
                           #                                                  "function(data, type, row, meta) {",
                           #                                                  "return type === 'display' && data.length > 50 ?",
                           #                                                  "'<span title=\"' + data + '\">' + data.substr(0, 50) + '...</span>' : data;",
                           #                                                  "}")
                           #                                              )
                           #                            )
                           columnDefs = list(
                             list(visible=F,targets=c(0)),
                             list(width=c(150),targets=c(4,6)),
                             list(width=c(70),targets=c(3,5)),
                             list(width=c(100),targets=c(7)),
                             list(width=c(100),targets=c(8)),
                             list(width=c(120),targets=c(9)),
                             list(className="dt-right",targets="_all")
                           )
                         )
      )
      widget
    }
  })
  
  #Returns the dataset in the form of a table
  output$CPVTable<-DT::renderDataTable({
    data<-CPVTable
    if (!is.null(dim(data))) {
      action = dataTableAjax(session, data)
      widget = datatable(data, 
                         server = TRUE, 
                         escape=F,
                         filter = 'top',
                         options = list(
                           dom= 'tlpi',
                           ajax = list(url = action),
                           lengthMenu = list(c(10, 100, -1), c('10', '100','All')),pageLength = 10,
                           autoWidth = T,
                           columnDefs = list(
                             list(visible=F,targets=c(0)),
                             list(width=c(70),targets=c(1:4)),
                             list(width=c(300),targets=c(5)),
                             list(className="dt-right",targets="_all")
                           )
                         )
      )
      widget
    }
  })
  
  extractURL<-function(link) {
    strsplit(link,"'")[[1]][2]
  }
  
  output$sankey<-renderSankeyNetwork({
    data<-sessionData$data[sessionData$currentData[,1],]
    sessionData$nbContracts<-nrow(data)
    valueToSelect<-'Contract value (€) - Exact'
    data<-data[which(data[,valueToSelect]>0),]
    sessionData$nbContractsMore0<-nrow(data)
    sessionData$totalValueContracts<-sum(data[,valueToSelect])
    sessionData$nbAuthority<-length(unique(as.character(data[,'Contracting authority SLUG'])))
    sessionData$nbContractors<-length(unique(as.character(data[,'Contractor SLUG'])))
    
    validate(
      need(nrow(data)<1000, paste0("Number of contracts with value>0 is ",nrow(data), ", the maximum is 1000. Please refine selection."))
    )
    
    i.NA<-which(data[,"Contracting authority SLUG"]=="")
    if (length(i.NA)>0) data[i.NA,"Contracting authority SLUG"]<-"NA"
    i.NA<-which(data[,"Contractor SLUG"]=="")
    if (length(i.NA)>0) data[i.NA,"Contractor SLUG"]<-"NA"
    
    data<-droplevels(data)
    pairscontracts<-paste(data$'Contracting authority SLUG',data$'Contractor SLUG',sep="_")
    
    sumpairs<-tapply(data[,valueToSelect],pairscontracts,sum)
    
    nNodes <- sort(unique(c(as.character(data[,'Contracting authority SLUG']),as.character(data[,'Contractor SLUG']))))
    
    nNodes <- unique(unlist(strsplit(names(sumpairs[sort(sumpairs,ind=T,dec=T)$ix]),"_")))
    
    nodes <- data.frame(id = 1:length(nNodes),
                        names = nNodes)
    
    relations <- (data[,c('Contracting authority SLUG','Contractor SLUG')])
    relations[,1]<-match(relations[,1],nodes$names)                                 
    relations[,2]<-match(relations[,2],nodes$names)
    names(relations) <- c("source", "target")
    links<-sapply(data[,2],extractURL)
    graphtable<-cbind(relations-1,value=data[,valueToSelect],link=links)
    
    graphtable<-graphtable[order(-graphtable[,3],graphtable[,1],graphtable[,2]),]
    
    nodes[,2]<-as.character(nodes[,2])
    i.match<-match(nodes[,2],data[,'Contracting authority SLUG'])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'Contracting authority name']
    i.match<-match(nodes[,2],data[,'Contractor SLUG'])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'Contractor name']
    
    for (i in 1:nrow(nodes)) {
      if (nchar(nodes[i,2])>65) nodes[i,2]<-paste0(substr(nodes[i,2],1,65),"...")
    }
    
    sessionData$heightSankey<-nrow(relations)*25
    
    sankeyNetwork(Links = graphtable[,1:4], Nodes = nodes,
                  Source = "source", Target = "target",
                  Value = "value", NodeID = "names", 
                  width = '100%', fontSize = 15, nodeWidth = 30,
                  nodePadding = 15,height=sessionData$heightSankey)
  })
  
  output$sankeyUI<-renderUI({
    fluidRow(
      fluidRow(
        strong("Summary"),p(),
        column(3,
               fluidRow(
                 "Number of contracting authority:",br(),
                 "Number of contractors:",br(),
                 "Total number of contracts:",br(),
                 "Number of contracts (values>0):",br(),
                 "Total value of contracts (€)",br()
               )
        ),
        column(2,
               fluidRow(
                 sessionData$nbAuthority,br(),
                 sessionData$nbContractors,br(),
                 sessionData$nbContracts,br(),
                 sessionData$nbContractsMore0,br(),
                 sessionData$totalValueContracts,br()
               )
        )
      )
      ,
      hr(),
      fluidRow(
        textOutput("nbRowsErrorMessage"),
        align="center"
      ),
      tags$div(class="extraspace5"),
      sankeyNetworkOutput('sankey',height=sessionData$heightSankey)
    )
  })
  
  createArchive<-function() {
    write.csv(sessionData$currentData[,-1], file="selection.csv", row.names=F)
  }
  
  output$downloadSelection <- downloadHandler(
    filename = function() {
      paste('data-opented-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(sessionData$currentData[,-1], con,row.names=F)
    }
  )
  
})
