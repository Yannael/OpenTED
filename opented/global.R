#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

dataNamesFields<-read.table("data/nameFields.txt",stringsAsFactors=F)
nameFields<-dataNamesFields[,1]
names(nameFields)<-dataNamesFields[,2]

CPVTable<-read.table("data/CPVTable.txt",stringsAsFactors=F)
colnames(CPVTable)<-c("CPV plain code","Category content")
