library(shiny)
library(htmlwidgets)
library(queryBuildR)
library(RMySQL)
library(DT)
library(networkD3)

shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  sessionData$heightSankey<-12500
  data<-loadData("data/TED_award_notices","awards","")
  sessionData$awards<-data$data
  sessionData$nbRowsErrorMessage<-data$nbRowsErrorMessage
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  output$nbRowsErrorMessageSankey<-renderText({
    sessionData$nbRowsErrorMessageSankey
  })
  
  observe({
    if (length(input$queryBuilderSQL)>0) {
      data<-loadData("data/TED_award_notices","awards",input$queryBuilderSQL)
      sessionData$awards<-data$data
      sessionData$nbRowsErrorMessage<-data$nbRowsErrorMessage
    }
  })
  
  output$queryBuilderWidget<-renderQueryBuildR({
    rules<-""
    filters<-initFilters
    queryBuildR(rules,filters)
  })
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$awards[,c(1,13,3:4,6:7,9:10,12)]
    colnames(data)<-as.vector(sapply(colnames(data),idToName))
    action <- dataTableAjax(session, data)
    datatable(data, 
              selection = 'none',
              escape=F,
              options = list(
                dom= 'C<"clear">litp',
                lengthMenu = list(c(10, 100, 1000), c('10', '100','1000')),pageLength = 10,
                ajax = list(url = action),
                columnDefs = list(
                  list(visible=F,targets=c(0)),
                  list(width=c(120),targets=c(4,6)),
                  list(width=c(60),targets=c(1:3,5,7:9)),
                  list(className="dt-right",targets="_all")
                )
              )
    )
  },server=T)
  
  #Returns the dataset in the form of a table
  output$CPVTable<-DT::renderDataTable({
    data<-CPVTable
    if (!is.null(dim(data))) {
      action = dataTableAjax(session, data)
      widget = datatable(data, 
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
  },server=T)
  
  extractURL<-function(link) {
    strsplit(link,"'")[[1]][2]
  }
  
  output$sankey<-renderSankeyNetwork({
    data<-sessionData$awards
    sessionData$nbContracts<-nrow(data)
    #data<-data[which(data[,'contract_value_euros']>0),]
    #browser()
    valueMore0<-which(data[,'contract_value_euros']>0)
    data[setdiff(1:nrow(data),valueMore0),'contract_value_euros']<- -1
    sessionData$nbContractsMore0<-length(valueMore0)
    sessionData$totalValueContracts<-sum(data[,'contract_value_euros'])
    sessionData$nbAuthority<-length(unique(as.character(data[,'contracting_authority_slug'])))
    sessionData$nbContractors<-length(unique(as.character(data[,'contractor_slug'])))
    
    validate(
      need(nrow(data)<=1000, paste0("Number of contracts with value>0 is ",nrow(data), ", the maximum is 1000. Please refine selection."))
    )
    
    i.NA<-which(data[,"contracting_authority_slug"]=="")
    if (length(i.NA)>0) data[i.NA,"contracting_authority_slug"]<-"NA"
    i.NA<-which(data[,"contractor_slug"]=="")
    if (length(i.NA)>0) data[i.NA,"contractor_slug"]<-"NA"
    
    data<-droplevels(data)
    pairscontracts<-paste(data$'contracting_authority_slug',data$'contractor_slug',sep="_")
    
    sumpairs<-tapply(data[,'contract_value_euros'],pairscontracts,sum)
    
    nNodes <- unique(unlist(strsplit(names(sumpairs[sort(sumpairs,ind=T,dec=T)$ix]),"_")))
    nodes <- data.frame(id = 1:length(nNodes),
                        names = nNodes)
    
    relations <- (data[,c('contracting_authority_slug','contractor_slug')])
    relations[,1]<-match(relations[,1],nodes$names)                                 
    relations[,2]<-match(relations[,2],nodes$names)
    names(relations) <- c("source", "target")
    links<-sapply(data[,13],extractURL)
    graphtable<-cbind(relations-1,value=data[,'contract_value_euros'],link=links)
    
    graphtable<-graphtable[order(-graphtable[,3],graphtable[,1],graphtable[,2]),]
    
    nodes[,2]<-as.character(nodes[,2])
    i.match<-match(nodes[,2],data[,'contracting_authority_slug'])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'contracting_authority_name']
    i.match<-match(nodes[,2],data[,'contractor_slug'])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'contractor_name']
    
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
        column(4,
               fluidRow(
                 "Number of contracting authority:",br(),
                 "Number of contractors:",br(),
                 "Total number of contracts:",br(),
                 "Number of contracts (values>0):",br(),
                 "Total value of contracts (€):",br()
               )
        ),
        column(4,
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
        textOutput("nbRowsErrorMessageSankey"),
        align="center"
      ),
      tags$div(class="extraspace5"),
      sankeyNetworkOutput('sankey',height=sessionData$heightSankey)
    )
  })
  
  output$downloadSelection <- downloadHandler(
    filename = function() {
      paste('data-opented-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(sessionData$awards, con,row.names=F)
    }
  )
  
})
