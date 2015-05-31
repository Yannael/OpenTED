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
  
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  #Modify award notices according to date/countries/CPV/value/offers filters
  updateAwardsNotice<-function(checkNbRows,dateRange) {
    if (checkNbRows) 
      fields<-'count(1)'
    else fields<-paste(nameFields[1:13],collapse=",")
    
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
      
      if (result>2500000) 
        sessionData$nbRowsErrorMessage<-paste0("Size limit exceeded: Current filters include ",result, " notices, the maximum is 500000.")
      else {
        isolate({
          awardNotices<-updateAwardsNotice(F,input$dateRange)
        })
        colnames(awardNotices)<-names(nameFields)
        sessionData$data<-awardNotices
        sessionData$currentData<-awardNotices
        sessionData$nbRowsErrorMessage<-""
      }
      
      setProgress(message = 'Retrieving data, please wait...',
                  value=3)
      
      
    })
  })
  
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$data[,c(1,2,4,5,7,8,10,11,13)]
    data[,3]<-as.factor(data[,3])
    data[,5]<-as.factor(data[,5])
    if (!is.null(dim(data))) {
      action = mydataTableAjax(session, data,sessionData=sessionData)
      widget = datatable(data, 
                         server = TRUE, 
                         escape=F,
                         filter = 'top',
                         options = list(
                           dom= 'itlpi',
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
                             list(width=c(70),targets=c(1)),
                             list(width=c(300),targets=c(2)),
                             list(className="dt-right",targets="_all")
                           )
                         )
      )
      widget
    }
  })
  
  output$sankey<-renderSankeyNetwork({
    load("../datafr.Rdata")
    
    pairscontracts<-paste(data$Government.authority.SLUG,data$Contractor.SLUG,sep="_")
    nbcontractperpairs<-tapply(pairscontracts,pairscontracts,length)
    nbcontractperpairs<-sort(nbcontractperpairs,dec=T)
    
    N<-1000
    
    pairs.select<-which(pairscontracts %in% names(nbcontractperpairs[2:N]))
    
    data<-droplevels(data[pairs.select,])
    pairscontracts<-paste(data$Government.authority.SLUG,data$Contractor.SLUG,sep="_")
    
    sumpairs<-tapply(data[,10],pairscontracts,sum)
    
    nNodes <- unique(c(as.character(data[,'Government.authority.SLUG']),as.character(data[,'Contractor.SLUG'])))
    
    nodes <- data.frame(id = 1:length(nNodes),
                        names = nNodes)
    
    relations <- (data[,c('Government.authority.SLUG','Contractor.SLUG')])
    relations[,1]<-match(relations[,1],nodes$names)                                 
    relations[,2]<-match(relations[,2],nodes$names)
    names(relations) <- c("source", "target")
    graphtable<-cbind(relations-1,value=data[,10])
    graphtable<-graphtable[order(graphtable[,1],graphtable[,2],-graphtable[,3]),]
    
    sankeyNetwork(Links = graphtable[,1:3], Nodes = nodes,
                  Source = "source", Target = "target",
                  Value = "value", NodeID = "names",
                  width = 700, fontsize = 12, nodeWidth = 30)
    
  })
  
  createGephiFiles<-function() {

    write.csv(sessionData$currentData[,-1], file="selection.csv", row.names=F)
    
    data<-sessionData$data[sessionData$currentData[,1],]
    
    i.remove<-which(is.na(data[,11]))
    if (length(i.remove)>0) data<-data[-i.remove,]
    
    acquired<-tapply(as.numeric(data[,11]),data[,9],length)
    awarded<-tapply(as.numeric(data[,11]),data[,6],length)
    avgcompauth<-tapply(as.numeric(data[,11]),data[,6],mean)
    avgcompcont<-tapply(as.numeric(data[,11]),data[,9],mean)
    
    avgcompauthcat<-floor(avgcompauth)
    avgcompauthcat[which(avgcompauthcat>6)]<-"6+"
    auth<-cbind(sort(unique(data[,6])),0,awarded,avgcompauth,avgcompauthcat,'true','false')
    
    avgcompcontcat<-floor(avgcompcont)
    avgcompcontcat[which(avgcompcontcat>6)]<-"6+"
    cont<-cbind(sort(unique(data[,9])),acquired,0,avgcompcont,avgcompcontcat,'false','true')
    
    nodes<-rbind(auth,cont)
    colnames(nodes)<-c("Id","Contracts acquired","Contracts awarded","Average competition","Average competition (Cat)","Authority","Company")
    
    edges<-unique(data[,c(6,9)])
    colnames(edges)<-c("Source","Target")
    
    write.csv(nodes, 'nodes.csv', row.names=F,quote=F)
    write.csv(edges, 'edges.csv', row.names=F,quote=F)
    
    nodesID<-data.frame(ID=1:nrow(nodes),name=nodes[,1])
    edges[,1]<-match(edges[,1],nodes[,1])
    edges[,2]<-match(edges[,2],nodes[,1])
    
    nodes[nodes[,5]=="6+",5]<-7
    nodescol<-as.numeric(nodes[,5])+1
    
    colors<-matrix(
      c(255,245,235,1,
        254,230,206,1,
        253,208,162,1,
        253,174,107,1,
        253,141,60,1,
        241,105,19,1,
        217,72,1,1,
        140,45,4,1),8,4,byrow=T)
    
    nodecolors<- data.frame(r = colors[nodescol,1],
                            g = colors[nodescol,2],
                            b = colors[nodescol,3],
                            a = colors[nodescol,4])
    
    graph <- write.gexf(nodes=nodesID,
                        edges=edges,
                        defaultedgetype='directed',
                        nodesVizAtt=list(
                          color=nodecolors,
                          size=10*(as.numeric(nodes[,2])+as.numeric(nodes[,3]))+100
                        ),
                        output="networkGephi.gexf")
    
  }
  
  output$downloadSelection <- downloadHandler(
    filename = function() {
      paste('data-gephi-', Sys.Date(), '.zip', sep='')
    },
    content = function(con) {
      createGephiFiles()
      zip(con,c('nodes.csv','edges.csv','networkGephi.gexf','selection.csv'))
    }
  )
  
})
