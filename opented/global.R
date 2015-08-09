#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

CPVTable<-read.table("data/CPVTable.txt",stringsAsFactors=F,colClasses=c("character"))
colnames(CPVTable)<-c("Original code","CPV plain code","NUM-digits", "Real Code", "Category content")
levelsCPV<-levels(as.factor(CPVTable[,2]))

loadData<-function(db,tablename,sql) {
  if (sql!="") sql<-paste0("where ",sql)
  condb<-dbConnect(RSQLite::SQLite(), paste0(db,".db"))
  nbrows<-dbGetQuery(condb,paste0("select count(*) from ",tablename," ",sql," order by official_journal_date asc"))
  limit<-""
  nbRowsErrorMessage<-""
  if (nbrows>1000) {
    limit<-" limit 1000"
    nbRowsErrorMessage<-paste0("Note: Your query returns ",nbrows," records. Only the first 1000 were retrieved. Refine selection with filters for a more focused set of results.")
  }
  data<-dbGetQuery(condb,paste0("select * from ",tablename," ",sql,limit))
  dbDisconnect(condb)
  list(data=data,nbRowsErrorMessage=nbRowsErrorMessage)
}

load('data/filters.Rdata')
initFilters<-filters
