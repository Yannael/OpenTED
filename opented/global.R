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
  action <- dataTableAjax(session, data,rownames=F)
  datatable(data, 
            selection = 'none',
            server=T,
            rownames=F,
            escape=F,
            options = list(
              dom= 'C<"clear">litp',
              lengthMenu = list(c(10, 100, 1000, 10000), c('10', '100','1000','10000')),pageLength = 10,
              ajax = list(url = action),
              columnDefs = list(
                list(className="dt-right",targets="_all")
              )
            )
  )
}
