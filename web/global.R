#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

authority_countries<-c("All",read.table("../authority_countries.txt",stringsAsFactors=F))
operator_countries<-c("All",read.table("../operator_countries.txt",stringsAsFactors=F))
CPV_code<-read.table("../CPV_code.txt",stringsAsFactors=F)

dataNamesFields<-read.table("../nameFields.txt",stringsAsFactors=F)
nameFields<-dataNamesFields[,1]
names(nameFields)<-dataNamesFields[,2]

defaultFieldsDisplay<-names(nameFields[c(1,2,4,5,8,9,10,11,13)])