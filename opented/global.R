#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

authority_countries<-c("All",read.table("data/authority_countries.txt",stringsAsFactors=F,col.names=F)[,1])
operator_countries<-c("All",read.table("data/operator_countries.txt",stringsAsFactors=F,col.names=F)[,1])

dataNamesFields<-read.table("data/nameFields.txt",stringsAsFactors=F)
nameFields<-dataNamesFields[,1]
names(nameFields)<-dataNamesFields[,2]
<<<<<<< HEAD:explorer/global.R

#defaultFieldsDisplay<-names(nameFields[c(1,2,4,5,8,9,10,11,13)])#
defaultFieldsDisplay<-names(nameFields[1:13])
=======
>>>>>>> DT:opented/global.R
