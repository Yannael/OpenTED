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
  
  output$sankey<-renderSankeyNetwork({
    data<-sessionData$data[sessionData$currentData[,1],]
    sessionData$nbContracts<-nrow(data)
    if (input$flowValues=="value") valueToSelect<-'Contract value (€) - Exact'
    else valueToSelect<-'Number offers received - Exact'
    if (nrow(data)>1000) 
      sessionData$nbRowsErrorMessage<-paste0("Number of selected contracts is ",nrow(data), ", the maximum is 1000. Please refine selection.")
    else {
      data<-data[which(data[,valueToSelect]>0),]
      sessionData$nbContractsMore0<-nrow(data)
      
      pairscontracts<-paste(data$'Contracting authority SLUG',data$'Contractor SLUG',sep="_")
      nbcontractperpairs<-tapply(pairscontracts,pairscontracts,length)
      nbcontractperpairs<-sort(nbcontractperpairs,dec=T)
      
      #N<-1000
      #pairs.select<-which(pairscontracts %in% names(nbcontractperpairs[1:N]))
      pairs.select<-1:nrow(data)
      
      data<-droplevels(data[pairs.select,])
      pairscontracts<-paste(data$'Contracting authority SLUG',data$'Contractor SLUG',sep="_")
      
      sumpairs<-tapply(data[,valueToSelect],pairscontracts,sum)
      
      nNodes <- sort(unique(c(as.character(data[,'Contracting authority SLUG']),as.character(data[,'Contractor SLUG']))))
      
      nodes <- data.frame(id = 1:length(nNodes),
                          names = nNodes)
      
      relations <- (data[,c('Contracting authority SLUG','Contractor SLUG')])
      relations[,1]<-match(relations[,1],nodes$names)                                 
      relations[,2]<-match(relations[,2],nodes$names)
      names(relations) <- c("source", "target")
      graphtable<-cbind(relations-1,value=data[,valueToSelect])
      graphtable<-graphtable[order(-graphtable[,3],graphtable[,1],graphtable[,2]),]
      
      nodes[,2]<-as.character(nodes[,2])
      i.match<-match(nodes[,2],data[,'Contracting authority SLUG'])
      nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'Contracting authority name']
      i.match<-match(nodes[,2],data[,'Contractor SLUG'])
      nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],'Contractor name']
      
     #nodes[,1]<-nodes[,1]-1
      
      sessionData$heightSankey<-nrow(relations)*25
      sessionData$nbAuthority<-length(unique(as.character(data[,'Contracting authority SLUG'])))
      sessionData$nbContractors<-length(unique(as.character(data[,'Contractor SLUG'])))
      
      sankeyNetwork(Links = graphtable[,1:3], Nodes = nodes,
                    Source = "source", Target = "target",
                    Value = "value", NodeID = "names",
                    width = '100%', fontsize = 15, nodeWidth = 30,
                    nodePadding = 15,height=sessionData$heightSankey)
    }
  })
  
  output$sankeyUI<-renderUI({
    fluidRow(
      fluidRow(
        radioButtons("flowValues", "Flow values:",
                     c("Contract values" = "value",
                       "Number of offers" = "nbOffers")
        )
      ),
      fluidRow(
        strong("Summary"),p(),
        column(3,
               fluidRow(
                 "Total number of contracts",br(),
                 "Number of contracts (values>0)",br(),
                 "Number of contracting authority:",br(),
                 "Number of contractors",br()
               )
        ),
        column(2,
               fluidRow(
                 sessionData$nbContracts,br(),
                 sessionData$nbContractsMore0,br(),
                 sessionData$nbAuthority,br(),
                 sessionData$nbContractors,br()
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
    
    #     data<-sessionData$data[sessionData$currentData[,1],]
    #     
    #     i.remove<-which(is.na(data[,11]))
    #     if (length(i.remove)>0) data<-data[-i.remove,]
    #     
    #     acquired<-tapply(as.numeric(data[,11]),data[,9],length)
    #     awarded<-tapply(as.numeric(data[,11]),data[,6],length)
    #     avgcompauth<-tapply(as.numeric(data[,11]),data[,6],mean)
    #     avgcompcont<-tapply(as.numeric(data[,11]),data[,9],mean)
    #     
    #     avgcompauthcat<-floor(avgcompauth)
    #     avgcompauthcat[which(avgcompauthcat>6)]<-"6+"
    #     auth<-cbind(sort(unique(data[,6])),0,awarded,avgcompauth,avgcompauthcat,'true','false')
    #     
    #     avgcompcontcat<-floor(avgcompcont)
    #     avgcompcontcat[which(avgcompcontcat>6)]<-"6+"
    #     cont<-cbind(sort(unique(data[,9])),acquired,0,avgcompcont,avgcompcontcat,'false','true')
    #     
    #     nodes<-rbind(auth,cont)
    #     colnames(nodes)<-c("Id","Contracts acquired","Contracts awarded","Average competition","Average competition (Cat)","Authority","Company")
    #     
    #     edges<-unique(data[,c(6,9)])
    #     colnames(edges)<-c("Source","Target")
    #     
    #     write.csv(nodes, 'nodes.csv', row.names=F,quote=F)
    #     write.csv(edges, 'edges.csv', row.names=F,quote=F)
    #     
    #     nodesID<-data.frame(ID=1:nrow(nodes),name=nodes[,1])
    #     edges[,1]<-match(edges[,1],nodes[,1])
    #     edges[,2]<-match(edges[,2],nodes[,1])
    #     
    #     nodes[nodes[,5]=="6+",5]<-7
    #     nodescol<-as.numeric(nodes[,5])+1
    #     
    #     colors<-matrix(
    #       c(255,245,235,1,
    #         254,230,206,1,
    #         253,208,162,1,
    #         253,174,107,1,
    #         253,141,60,1,
    #         241,105,19,1,
    #         217,72,1,1,
    #         140,45,4,1),8,4,byrow=T)
    #     
    #     nodecolors<- data.frame(r = colors[nodescol,1],
    #                             g = colors[nodescol,2],
    #                             b = colors[nodescol,3],
    #                             a = colors[nodescol,4])
    #     
    #     graph <- write.gexf(nodes=nodesID,
    #                         edges=edges,
    #                         defaultedgetype='directed',
    #                         nodesVizAtt=list(
    #                           color=nodecolors,
    #                           size=10*(as.numeric(nodes[,2])+as.numeric(nodes[,3]))+100
    #                         ),
    #                         output="networkGephi.gexf")
    #     
  }
  
  output$downloadSelection <- downloadHandler(
    filename = function() {
      paste('data-opented-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      #createArchive()
      write.csv(sessionData$currentData[,-1], con,row.names=F)
      #zip(con,c('nodes.csv','edges.csv','networkGephi.gexf','selection.csv'))
      
    }
  )
  
})
