library(RMySQL)
library(queryBuildR)

#TED contracts is from http://ted.openspending.org/data/ted-contracts.csv
#Load contract awards
system.time(contracts<-read.table("dataAll/ted-contracts.csv",header=T,sep=","))

#Put them in a local file DB
con <- dbConnect(RSQLite::SQLite(), "TED.db")
dbWriteTable(con,"contracts",contracts)
dbDisconnect(con)

#Get subset of fields of interest from DB
con <- dbConnect(RSQLite::SQLite(), "TED.db")
data<-dbGetQuery(con,"select document_oj_date,contract_doc_no,contract_authority_country, contract_authority_official_name, contract_authority_slug, contract_operator_country, contract_operator_official_name,contract_operator_slug, contract_contract_value_cost_eur,contract_offers_received_num,document_award_criteria,contract_cpv_code from contracts")
dbDisconnect(con)

##################
#Some basic data curation

#If CPV NA, put 00000000 instead
na.cpv<-which(is.na(data[,'contract_cpv_code']))
data[na.cpv,'contract_cpv_code']<-'00000000'

#Check for CPVs with length 7, for which a 0 is missing
add0<-which(sapply(data[,'contract_cpv_code'],nchar)==7)
data[add0,'contract_cpv_code']<-paste0("0",data[add0,'contract_cpv_code'])

#Round contract values (in euros), too many decimals in there
data[,'contract_contract_value_cost_eur']<-round(data[,'contract_contract_value_cost_eur'])

#Make dates look nice
#Take a string YYYMMDD and makes it YYY-MM-DD
niceDate<-function(date_input) {
  s<-as.character(date_input)
  year<-substr(as.character(s),1,4)
  month<-substr(as.character(s),5,6)
  day<-substr(as.character(s),7,8)
  paste(year,month,day,sep='-')
}
data[,'document_oj_date']<-sapply(data[,'document_oj_date'],niceDate)

#Creates names for award notices, in the format docID-Year
createName<-function(s) {
  paste0(s[2],'-',s[1])
}

#Create proper award notice document ID from the contract_doc_no field in OpenTED CSV
namesDoc<-as.character(unlist(lapply(sapply(data[,"contract_doc_no"],strsplit,"/S (.*)-"),createName)))
data[,'contract_doc_no']<-namesDoc

#Create HTML links to webpages on TED website
linkDoc<-paste0("<a href='http://ted.europa.eu/udl?uri=TED:NOTICE:",namesDoc,":TEXT:EN:HTML&src=0' target='_blank'>",namesDoc,'</a>')
data<-cbind(data,'linkDoc'=linkDoc)

##################
#Store results in folder 'data'
dir.create('data')

#Define column names
colnames(data)<-c("official_journal_date","award_notice_id","contracting_authority_country","contracting_authority_name","contracting_authority_slug","contractor_country","contractor_name","contractor_slug","contract_value_euros","number_offers_received","award_criteria","CPV_code","award_notice_id_link")

#Order by date
data<-data[order(data[,1]),]

#Create a subset DB for fields of interests
con <- dbConnect(RSQLite::SQLite(), "data/TED_award_notices.db")
dbWriteTable(con,"awards",data,overwrite=T,row.names=F)
dbDisconnect(con)

#Create filters

data2<-data[,c(1:4,6:7,9:10,12)]
data2[,3]<-factor(data2[,3])
data2[,5]<-factor(data2[,5])
filters<-getFiltersFromTable(data2)
filters[[1]]$operators<-list('equal','not_equal',  'less', 'less_or_equal', 'greater','greater_or_equal')
save(file='filters.Rdata',filters)

#Grab CPV coes from OpenTed Github
#rawfile<-getURL("https://raw.githubusercontent.com/opented/opented/master/cpvcodes/cpvcodes.csv")
#CPVTable <- read.csv(textConnection(rawfile),colClasses=c("character"))
CPVTable <- read.csv(file="opented/data/cpvcodes.csv",colClasses=c("character"))
CPVTable<-CPVTable[,c(1,2,3,4,5)]
CPVTable[,5]<-iconv(CPVTable[,5], from="latin1" ,to="UTF-8")
write.table(file="data/CPVTable.txt",CPVTable,row.names=F,col.names=F)





