library(shiny)
library(RMySQL)
library(DT)
library(RCurl)
library(networkD3)

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
    
    country_select_authority<-""
    country_select_operator<-""
    CPV<-""
    #if ((CPVFrom!="") & (CPVTo != "")) CPV<-paste0(" and contract_cpv_code>=",CPVFrom," and contract_cpv_code<=",CPVTo)
    value<-""
    #if ((valueFrom!="") & (valueTo != "")) value<-paste0(" and contract_contract_value_cost_eur>=",valueFrom," and contract_contract_value_cost_eur<=",valueTo)
    nbOffers<-""
    #if ((nbOffersFrom!="") & (nbOffersTo != "")) nbOffers<-paste0(" and contract_offers_received_num>=",nbOffersFrom," and contract_offers_received_num<=",nbOffersTo)
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
  
  shinyFun = function(name) getFromNamespace(name, 'shiny')
  
  require(lubridate)
  
  dataTablesFilter = function(data, params) {
    n = nrow(data)
    q = params
    ci = q$search[['caseInsensitive']] == 'true'
    
    # global searching
    i = seq_len(n)
    # for some reason, q$search might be NULL, leading to error `if (logical(0))`
    if (isTRUE(q$search[['value']] != '')) {
      i0 = apply(data, 2, function(x) {
        grep2(q$search[['value']], as.character(x),
              fixed = q$search[['regex']] == 'false', ignore.case = ci)
      })
      i = intersect(i, unique(unlist(i0)))
    }
    
    # search by columns
    if (length(i)) for (j in names(q$columns)) {
      col = q$columns[[j]]
      # if the j-th column is not searchable or the search string is "", skip it
      if (col[['searchable']] != 'true') next
      if ((k <- col[['search']][['value']]) == '') next
      j = as.integer(j)
      dj = data[, j + 1]
      ij = if (is.numeric(dj) || is.Date(dj)) {
        r = commaToRange(k)
        if (length(r) != 2)
          stop('The range of a numeric / date / time column must be of length 2')
        if (is.Date(dj)) {
          # r is milliseconds
          r = as.POSIXct(r / 1000, origin = '1970-01-01')
          if (inherits(dj, 'Date')) r = as.Date(r)
        }
        which(dj >= r[1] & dj <= r[2])
      } else if (is.factor(dj)) {
        which(dj %in% jsonlite::fromJSON(k))
      } else {
        grep2(k, as.character(dj), fixed = col[['search']][['regex']] == 'false',
              ignore.case = ci)
      }
      i = intersect(ij, i)
      if (length(i) == 0) break
    }
    if (length(i) != n) data = data[i, , drop = FALSE]
    
    # sorting
    oList = list()
    for (ord in q$order) {
      k = ord[['column']]  # which column to sort
      d = ord[['dir']]     # direction asc/desc
      if (q$columns[[k]][['orderable']] != 'true') next
      col = data[, as.integer(k) + 1]
      oList[[length(oList) + 1]] = (if (d == 'asc') identity else `-`)(
        if (is.numeric(col)) col else xtfrm(col)
      )
    }
    if (length(oList)) {
      i = do.call(order, oList)
      data = data[i, , drop = FALSE]
    }
    # paging
    if (q$length != '-1') {
      i = seq(as.integer(q$start) + 1L, length.out = as.integer(q$length))
      i = i[i <= nrow(data)]
      fdata = data[i, , drop = FALSE]  # filtered data
    } else fdata = data
    
    fdata = unname(as.matrix(fdata))
    if (is.character(fdata) && q$escape != 'false') {
      if (q$escape == 'true') fdata = htmlEscape(fdata) else {
        k = as.integer(strsplit(q$escape, ',')[[1]])
        # use seq_len() in case escape = negative indices, e.g. c(-1, -5)
        for (j in seq_len(ncol(fdata))[k]) fdata[, j] = htmlEscape(fdata[, j])
      }
    }
    
    sessionData$currentData<-data
    
    list(
      draw = as.integer(q$draw),
      recordsTotal = n,
      recordsFiltered = nrow(data),
      data = fdata
    )
  }
  
  # when both ignore.case and fixed are TRUE, we use grep(ignore.case = FALSE,
  # fixed = TRUE) to do lower-case matching of pattern on x
  grep2 = function(pattern, x, ignore.case = FALSE, fixed = FALSE, ...) {
    if (fixed && ignore.case) {
      pattern = tolower(pattern)
      x = tolower(x)
      ignore.case = FALSE
    }
    # when the user types in the search box, the regular expression may not be
    # complete before it is sent to the server, in which case we do not search
    if (!fixed && inherits(try(grep(pattern, ''), silent = TRUE), 'try-error'))
      return(seq_along(x))
    grep(pattern, x, ignore.case = ignore.case, fixed = fixed, ...)
  }
  
  # convert a string of the form "lower,upper" to c(lower, upper)
  commaToRange = function(string) {
    if (!grepl(',', string)) return()
    r = strsplit(string, ',')[[1]]
    if (length(r) > 2) return()
    if (length(r) == 1) r = c(r, '')  # lower,
    r = as.numeric(r)
    if (is.na(r[1])) r[1] = -Inf
    if (is.na(r[2])) r[2] = Inf
    r
  }
  
  mydataTableAjax = function(session, data, rownames, filter = dataTablesFilter) {
    oop = options(stringsAsFactors = FALSE); on.exit(options(oop), add = TRUE)
    
    # abuse tempfile() to obtain a random id unique to this R session
    id = basename(tempfile(''))
    
    # deal with row names: rownames = TRUE or missing, use rownames(data)
    rn = if (missing(rownames) || isTRUE(rownames)) base::rownames(data) else {
      if (is.character(rownames)) rownames  # use custom row names
    }
    data = as.data.frame(data)  # think dplyr
    if (length(rn)) data = cbind(' ' = rn, data)
    
    URLdecode = shinyFun('URLdecode')
    toJSON = shinyFun('toJSON')
    httpResponse = shinyFun('httpResponse')
    
    filterFun = function(data, req) {
      # DataTables requests were sent via POST
      params = URLdecode(rawToChar(req$rook.input$read()))
      Encoding(params) = 'UTF-8'
      # use system native encoding if possible (again, this grep(fixed = TRUE) bug
      # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16264)
      params2 = iconv(params, 'UTF-8', '')
      if (!is.na(params2)) params = params2 else warning(
        'Some DataTables parameters contain multibyte characters ',
        'that do not work in current locale.'
      )
      params = shiny::parseQueryString(params, nested = TRUE)
      
      res = tryCatch(filter(data, params), error = function(e) {
        list(error = as.character(e))
      })
      httpResponse(200, 'application/json', enc2utf8(toJSON(res)))
    }
    
    session$registerDataObj(id, data, filterFun)
  }
  
  #Returns the dataset in the form of a table
  output$awardTable<-DT::renderDataTable({
    data<-sessionData$data[,c(1,2,4,5,7,8,10,11,13)]
    data[,3]<-as.factor(data[,3])
    data[,5]<-as.factor(data[,5])
    if (!is.null(dim(data))) {
      action = mydataTableAjax(session, data)
      widget = datatable(data, 
                         server = TRUE, 
                         #extensions = c('Scroller'),
                         escape=F,
                         filter = 'top',
                         options = list(
                           #dom= 'plrti',
                           dom= 'itlp',
                           #scrollX = T,
                           ajax = list(url = action),
                           #deferRender = TRUE,
                           #scrollY = 500,
                           #scrollCollapse = T,
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
  
  output$downloadAwards <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(sessionData$currentData, con, row.names=F)
    }
  )
  
})
