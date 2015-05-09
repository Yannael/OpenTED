#Be careful to run this you need at least 8GB of free RAM. If you don't, run by chunks (i.e. load a CSV, add to the DB, and so on) 

#Load all CSV
contracts2015<-read.table("ted-contracts-2015.csv",header=T,sep=",")
contracts2014<-read.table("ted-contracts-2014.csv",header=T,sep=",")
contracts2013<-read.table("ted-contracts-2013.csv",header=T,sep=",")
contracts2012<-read.table("ted-contracts-2012.csv",header=T,sep=",")

#Put them in a local file DB
con <- dbConnect(RSQLite::SQLite(), "TED.db")
dbWriteTable(con,"contracts",contracts2015)
dbWriteTable(con,"contracts",contracts2014,append=T,overwrite=F)
dbWriteTable(con,"contracts",contracts2013,append=T,overwrite=F)
dbWriteTable(con,"contracts",contracts2012,append=T,overwrite=F)
dbDisconnect(con)

#Get subset of fields of interest from DB
con <- dbConnect(RSQLite::SQLite(), "TED.db")
rs<-dbSendQuery(con,"select document_oj_date,contract_doc_no,contract_authority_country, contract_authority_official_name, contract_operator_country, contract_operator_official_name,contract_contract_value_cost_eur,document_award_criteria,contract_cpv_code from contracts where contract_contract_value_cost_eur>0")
data_sub = fetch(rs, n=-1)
dbClearResult(rs)
dbDisconnect(con)

##################
#Some basic data curating

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

#Create HTML links to webpages on TED website
linkDoc<-paste0("<a href='http://ted.europa.eu/udl?uri=TED:NOTICE:",namesDoc,":TEXT:EN:HTML&src=0' target='_blank'>",namesDoc,'</a>')
data[,'contract_doc_no']<-linkDoc

##################

#Create a subset DB for fields of interests
con <- dbConnect(RSQLite::SQLite(), "TED_curated_contracts.db")
dbWriteTable(con,"contracts",data)
dbDisconnect(con)

#Note: Original DB is about 3GB. The resulting TED_curated_contracts.db file is about 250MB.

