#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

CPVTable<-read.table("data/CPVTable.txt",stringsAsFactors=F,colClasses=c("character"))
colnames(CPVTable)<-c("Original code","CPV plain code","NUM-digits", "Real Code", "Category content")
levelsCPV<-levels(as.factor(CPVTable[,2]))

loadData<-function(db,tablename,sql) {
  if (sql!="") sql<-paste0("where ",sql)
  condb<-dbConnect(RSQLite::SQLite(), paste0(db,".db"))
  data<-dbGetQuery(condb,paste0("select * from ",tablename," ",sql," limit 1000"))
  dbDisconnect(condb)
  data
}

getWidgetTable<-function(data,session) {
  data[is.na(data)]<-"bla"
  action <- dataTableAjax(session, data,rownames=F)
  widget<-datatable(data, 
                    extensions = 'Scroller',
                    server = TRUE, 
                    selection = 'single',
                    rownames=F,
                    escape=F,
                    options = list(
                      dom= 'itS',
                      deferRender = TRUE,
                      scrollY = 335,
                      ajax = list(url = action),
                      columnDefs = list(
                        list(className="dt-right",targets="_all")
                      )
                    )
  )
  widget
}
