shinyServer(function(input, output,session) {
  
  sessionData <- reactiveValues()
  sessionData$heightSankey<-12500
  data<-loadDataParquet("")
  sessionData$awards<-data$data
  sessionData$nbRowsErrorMessage<-data$nbRowsErrorMessage
  sessionData$queries<-queries
  sessionData$queries.sql<-query.sql
  
  output$nbRowsErrorMessage<-renderText({
    sessionData$nbRowsErrorMessage
  })
  
  output$nbRowsErrorMessageSankey<-renderText({
    sessionData$nbRowsErrorMessageSankey
  })
  
  observe({
    if (length(input$queryBuilderSQL)>0) {
      data<-loadDataParquet(input$queryBuilderSQL)
      sessionData$awards<-data$data
      sessionData$nbRowsErrorMessage<-data$nbRowsErrorMessage
    }
  })
  
  observe({
    query<-input$queryid
    if (length(query)>0) {
      query<-substr(query,2,nchar(query))
      if (query!="") {
        sqlQuery<-sessionData$queries.sql[as.numeric(query)]
        sqlQuery<-gsub("official_journal_date","Dispatch_Date",sqlQuery)
        sqlQuery<-gsub("contracting_authority_country","Contracting_Authority_Country",sqlQuery)
        sqlQuery<-gsub("CPV_code","CPV_Code",sqlQuery)
        data<-loadDataParquet(sqlQuery)
        sessionData$awards<-data$data
        sessionData$nbRowsErrorMessage<-data$nbRowsErrorMessage
      }
    }
  })
  
  output$showVarUI<-renderUI({
    isolate({
      niceNames<-as.vector(sapply(colnames(sessionData$awards),idToName))
      selectInput('showVar', 'Select variables to display', niceNames, 
                  selected=niceNames[c(1:9)],multiple=TRUE, selectize=TRUE,width='1050px')
    })
  })
  
  output$queryBuilderWidget<-renderQueryBuildR({
    rules<-""
    query<-input$queryid
    if (length(query)>0) {
      query<-substr(query,2,nchar(query))
      if (query!="") {
        rules<-sessionData$queries[[as.numeric(query)]]
        rules$rules[[1]]$id<-"Contracting_Authority_Country"
        rules$rules[[2]]$id<-"CPV_Code"
        rules$rules[[3]]$id<-"Dispatch_Date"
        rules$rules[[4]]$id<-"Dispatch_Date"
      }
    }
    filters<-initFilters
    queryBuildR(rules,filters)
  })
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    if (length(input$showVar)>0) {
      data<-sessionData$awards[,sapply(input$showVar,nameToId)]
      colnames(data)<-input$showVar
      action <- dataTableAjax(session, data)
      datatable(data, 
                selection = 'none',
                escape=F,
                options = list(
                  dom= 'C<"clear">litp',
                  lengthMenu = list(c(10, 100, 1000), c('10', '100','1000')),pageLength = 10,
                  ajax = list(url = action),
                  #autoWidth = T,
                  columnDefs = list(
                    list(visible=F,targets=c(0)),
                    list(width=c(150),targets=c(4,6)),
                    list(width=c(60),targets=c(1:9)),
                    list(className="dt-right",targets="_all")
                  )
                )
      )
    }
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
    
    nameSource<-'Contracting_Authority_Name'
    nameTarget<-'Contractor_Name'
    
    nbContracts<-input$nbAwardsSankey
    if (nbContracts=='All') nbContracts<-1000
    nbContracts<-as.numeric(nbContracts)
    
    data<-sessionData$awards
    
    if (nbContracts>nrow(data)) nbContracts<-nrow(data)
    data<-data[1:nbContracts,]
    
    sessionData$nbContracts<-nrow(data)
    
    valueMore0<-which(data[,'Contract_Value_Euros']>0)
    if (length(setdiff(1:nrow(data),valueMore0))>0) data[setdiff(1:nrow(data),valueMore0),'Contract_Value_Euros']<- -1
    #if (length(valueMore0)>0) data[valueMore0,'Contract_Value_Euros']<- log10(data[valueMore0,'Contract_Value_Euros'])
    sessionData$nbContractsMore0<-length(valueMore0)
    sessionData$totalValueContracts<-sum(data[,'Contract_Value_Euros'])
    sessionData$nbAuthority<-length(unique(as.character(data[,nameSource])))
    sessionData$nbContractors<-length(unique(as.character(data[,nameTarget])))
    
    targetIsSource<-intersect(unique(as.character(data[,nameSource])),unique(as.character(data[,nameTarget])))
    if (length(targetIsSource)>0) {
      for (i in 1:length(targetIsSource)) {
        i.match<-which(as.character(data[,nameTarget])==targetIsSource[i])
        data[i.match,nameTarget]<-paste0(targetIsSource[i],"-2")
      }
    }
    validate(
      need(nrow(data)<=1000, paste0("Number of contracts with value>0 is ",nrow(data), ", the maximum is 1000. Please refine selection."))
    )
    i.NA<-which(is.na(data[,nameSource]))
    if (length(i.NA)>0) data[i.NA,nameSource]<-"Unknown authority"
    i.NA<-which(is.na(data[,nameTarget]))
    if (length(i.NA)>0) data[i.NA,nameTarget]<-"Unknown contractor"
    data<-droplevels(data)
    pairscontracts<-paste(data[,nameSource],data[,nameTarget],sep="_")
    
    sumpairs<-tapply(data[,'Contract_Value_Euros'],pairscontracts,sum)
    
    nNodes <- unique(unlist(strsplit(names(sumpairs[sort(sumpairs,ind=T,dec=T)$ix]),"_")))
    nodes <- data.frame(id = 1:length(nNodes),
                        names = nNodes,stringsAsFactors=F)
    relations <- (data[,c(nameSource,nameTarget)])
    
    relations[,1]<-match(relations[,1],nodes$names)
    relations[,2]<-match(relations[,2],nodes$names)
    names(relations) <- c("source", "target")
    
    links<-sapply(data[,"Award_Notice_Id_Link"],extractURL)
    graphtable<-cbind(relations-1,value=data[,'Contract_Value_Euros'],link=links)
    
    graphtable<-graphtable[order(-graphtable[,3],graphtable[,1],graphtable[,2]),]
    
    nodes[,2]<-as.character(nodes[,2])
    i.match<-match(nodes[,2],data[,nameSource])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],nameSource]
    i.match<-match(nodes[,2],data[,nameTarget])
    nodes[which(!is.na(i.match)),2]<-data[i.match[!is.na(i.match)],nameTarget]
    
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
        shiny::column(4,
                      fluidRow(
                        "Number of contracting authority:",br(),
                        "Number of contractors:",br(),
                        "Total number of contracts:",br(),
                        "Number of contracts (values>0):",br(),
                        "Total value of contracts (€):",br()
                      )
        ),
        shiny::column(4,
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
