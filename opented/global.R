#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

CPVTable<-read.table("data/CPVTable.txt",stringsAsFactors=F,colClasses=c("character"))
colnames(CPVTable)<-c("Original code","CPV plain code","NUM-digits", "Real Code", "Category content")
levelsCPV<-levels(as.factor(CPVTable[,2]))

loadData<-function(db,tablename,sql) {
  if (sql!="") sql<-paste0("where ",sql)
  condb<-dbConnect(RSQLite::SQLite(), paste0(db,".db"))
  nbrows<-dbGetQuery(condb,paste0("select count(*) from ",tablename," ",sql))
  limit<-""
  nbRowsErrorMessage<-""
  if (nbrows>100000) {
    limit<-" limit 100000"
    nbRowsErrorMessage<-paste0("Warning: Your query returns ",nbrows," records The table below only includes the first 100000.")
  }
  data<-dbGetQuery(condb,paste0("select * from ",tablename," ",sql,limit))
  dbDisconnect(condb)
  list(data=data,nbRowsErrorMessage=nbRowsErrorMessage)
}

