library("RMySQL")
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
rs<-dbSendQuery(con,"select document_oj_date,contract_doc_no,contract_location_nuts, contract_authority_country, contract_authority_official_name, contract_authority_slug, contract_operator_country, contract_operator_official_name,contract_operator_slug, contract_contract_value_cost_eur,contract_offers_received_num,document_award_criteria,contract_cpv_code from contracts")
data = fetch(rs, n=-1)
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
#Store results in folder 'data'
dir.create('data')

#Create a subset DB for fields of interests
con <- dbConnect(RSQLite::SQLite(), "data/TED_award_notices.db")
dbWriteTable(con,"contracts",data,overwrite=T)
dbDisconnect(con)

#Note: Original DB is about 3GB. The resulting TED_curated_contracts.db file is about 250MB.


#Save countries present in DB 
#Note there are errors in the dataset, some country ID are clearly not right, e.g., "1A"
authority_countries<-sort(unique(data[,'contract_authority_country']))
write.table(file="data/authority_countries.txt",authority_countries,row.names=F,col.names=F)

operator_countries<-sort(unique(data[,'contract_operator_country']))
write.table(file="data/operator_countries.txt",operator_countries,row.names=F,col.names=F)

#Save names of fields and their 'nice' meaning
nameFields<-colnames(data)
nameFields<-cbind(nameFields,c("Official journal date","Award notice ID","Contract location NUTS", "Contracting authority country","Contracting authority name","Contracting authority SLUG","Contractor country","Contractor name","Contractor SLUG","Contract value (€)","Number offers received","Award criteria","CPV code"))
write.table(file="data/nameFields.txt",nameFields,row.names=F,col.names=F)

#Save CPV codes
CPVcodes<-sort(unique(data[,'contract_cpv_code']))
write.table(file="data/CPVcodes.txt",CPVcodes,row.names=F,col.names=F)

#Returns a bar plot with the number of award notices per contract authority country
output$authorityCountryBarPlot<-renderPlot({
  data<-sessionData$data
  uniqueAuthorityContract<-unique(data[,c('contract_doc_no','contract_authority_country')])
  plot_return<-ggplot(uniqueAuthorityContract, aes(factor(contract_authority_country)))+
    geom_bar()+coord_flip()+
    xlab("Country")+
    ylab("Number of award notices")
  plot_return
}, height = 800, width = 900)

#Returns a bar plot with the total value of awards (in Euro) per contract authority country
output$valueCountryBarPlot<-renderPlot({
  data<-sessionData$data
  plot_return<-ggplot(data,aes(contract_authority_country,y=contract_contract_value_cost_eur))+
    geom_bar(stat="identity")+coord_flip()+
    xlab("Country")+
    ylab("Total value of awards")
  plot_return
}, height = 800, width = 900)




