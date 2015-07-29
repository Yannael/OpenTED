library(shiny)
library(htmlwidgets)
library(queryBuildR)
library(RMySQL)
library(DT)
library(RCurl)
library(networkD3)

shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  sessionData$nbRowsErrorMessage<-""
  sessionData$heightSankey<-12500
  sessionData$awards<-loadData("data/TED_award_notices","awards","")
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  observe({
    if (length(input$queryBuilderSQL)>0)
      #sessionData$awards<-loadData("data/TED_award_notices","awards",input$queryBuilderSQL)
      a<-1
  })
  
  output$showVarAwardsUI<-renderUI({
    selectInput('showVarAwards', 'Display variables', colnames(sessionData$awards), 
                selected=colnames(sessionData$awards),multiple=TRUE, selectize=TRUE)
  })
  
  
  output$queryBuilderWidget<-renderQueryBuildR({
    data<-sessionData$awards[,c(1:4,6:7,9:12)]
    rules<-NULL
    filters<-getFiltersFromTable(data)
    widget<-queryBuildR(rules,filters)
    
    widget
  })
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    if (length(data)) {
    data<-sessionData$awards[,c(1:4,6:7,9:12)]
    colnames(data)<-as.vector(sapply(colnames(data),idToName))
    getWidgetTable(data,session)
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
