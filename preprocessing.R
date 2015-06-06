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

#If CPV NA, put 00000000 instead
na.cpv<-which(is.na(data[,'contract_cpv_code']))
data[na.cpv,'contract_cpv_code']<-'00000000'

#Check for CPVs with length 7, for which a 0 is missing
add0<-which(sapply(data[,'contract_cpv_code'],nchar)==7)
data[add0,'contract_cpv_code']<-paste0("0",data[add0,'contract_cpv_code'])

#Get category of contract value
getCatValue<-function(val) {
  if (is.na(val)) return("NA")
  if (val>=0 & val<1000) return("1-1K")
  if (val>=1000 & val<10000) return("1K-10K")
  if (val>=10000 & val<100000) return("10K-100K")
  if (val>=100000 & val<1000000) return("100K-1M")
  if (val>=1000000 & val<10000000) return("1M-10M")
  if (val>=10000000) return(">10M")
}

catValue<-factor(unlist(sapply(data[,'contract_contract_value_cost_eur'],getCatValue)),levels=c("NA","1-1K","1K-10K","10K-100K","100K-1M","1M-10M",">10M"))

data<-cbind(data,catValue)

#Get category of nb offers value
getCatOffers<-function(val) {
  if (is.na(val)) return("NA")
  if (val>=0 & val<7) return(as.character(val))
  if (val>6) return(">6")
}

catOffers<-factor(unlist(sapply(data[,'contract_offers_received_num'],getCatOffers)),levels=c("NA","1","2","3","4","5","6",">6"))

data<-cbind(data,catOffers)

#Round contract values (in euros), too many decimals in there
data[,'contract_contract_value_cost_eur']<-round(data[,'contract_contract_value_cost_eur'])

#Create category for contract value


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

#Save names of fields and their 'nice' meaning
nameFields<-colnames(data)
nameFields<-cbind(nameFields,c("Official journal date","Award notice ID","Contract location NUTS", "Contracting authority country","Contracting authority name","Contracting authority SLUG","Contractor country","Contractor name","Contractor SLUG","Contract value (€) - Exact","Number offers received - Exact","Award criteria","CPV code","Contract value (€)","Number offers received"))
write.table(file="data/nameFields.txt",nameFields,row.names=F,col.names=F)

#Save CPV codes
CPVcodes<-sort(unique(data[,'contract_cpv_code']))
write.table(file="data/CPVcodes.txt",CPVcodes,row.names=F,col.names=F)

#Grab CPV coes from OpenTed Github
#rawfile<-getURL("https://raw.githubusercontent.com/opented/opented/master/cpvcodes/cpvcodes.csv")
#CPVTable <- read.csv(textConnection(rawfile),colClasses=c("character"))
CPVTable <- read.csv(file="opented/data/cpvcodes.csv",colClasses=c("character"))
CPVTable<-CPVTable[,c(1,2,3,4,5)]
CPVTable[,5]<-iconv(CPVTable[,5], from="latin1" ,to="UTF-8")
write.table(file="data/CPVTable.txt",CPVTable,row.names=F,col.names=F)

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




