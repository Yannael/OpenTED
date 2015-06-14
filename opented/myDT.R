shinyFun = function(name) getFromNamespace(name, 'shiny')

require(lubridate)

mydataTablesFilter = function(data, params,sessionData) {
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
      if (j==9) {
        if (!is.na(as.numeric(jsonlite::fromJSON(k)))) {
          cpvcodes<-jsonlite::fromJSON(k)
          i.tokeep<-c()
          for (cpvcode in 1:length(cpvcodes)) {
            fromCPV<-cpvcodes[cpvcode]
            toCPV<-fromCPV
            pos.lng<-regexpr("(0+)$",fromCPV)
            if (pos.lng[1]>-1) {
              toCPV<-paste0(as.numeric(substr(fromCPV,1,pos.lng[1]-1))+1,paste0(rep("0",8-pos.lng[1]+1),collapse=""))
              if (nchar(toCPV)==7) toCPV<-paste0(0,toCPV)
            }
            #which(dj %in% jsonlite::fromJSON(k))
            djc<-as.character(dj)
            i.tokeep<-c(i.tokeep,which(djc>=fromCPV & djc<toCPV))
          }
          i.tokeep
        }
      }
      else {
        which(dj %in% jsonlite::fromJSON(k))
      }
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

mydataTableAjax = function(session, data, rownames, filter = mydataTablesFilter,sessionData) {
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
    
    res = tryCatch(filter(data, params,sessionData), error = function(e) {
      list(error = as.character(e))
    })
    httpResponse(200, 'application/json', enc2utf8(toJSON(res)))
  }
  
  session$registerDataObj(id, data, filterFun)
}
