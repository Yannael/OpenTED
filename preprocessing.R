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


countrycode<-read.csv("countrycodes.csv",sep="°",stringsAsFactors=F,header=F)
countrycode<-matrix(unlist(sapply(countrycode,strsplit," - ")),252,2,byrow=T)
data[,3]<-countrycode[match(data[,3],countrycode[,1]),2]
data[,6]<-countrycode[match(data[,6],countrycode[,1]),2]

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


#######
#Webste lmottery

dummy<-function() {
  
  cpvtable<-read.table("opented/data/CPVTable.txt",stringsAsFactors=F)
  country <- c("Austria","Belgium","Bulgaria","Cyprus","Croatia","Czech Republic","Denmark","Estonia","Finland","France","Germany","Greece","Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg","Malta","Netherlands","Poland","Portugal","Romania","Slovakia","Slovenia","Spain","Sweden","United Kingdom")
  cpv <- cpvtable[which(nchar(cpvtable[,4])==3),4:5]
  years <- c("2012", "2013", "2014", "2012 to 2013", "2013 to 2014", "2012 to 2014")
  
  con <- dbConnect(RSQLite::SQLite(), "opented/data/TED_award_notices.db")
  data<-dbReadTable(con,'awards')
  
  set.seed(2)
  subset<-data[,c(1,3,12)]
  
  getyear<-function(d) {
    strsplit(d,'-')[[1]][1]
  }
  
  getcpv3<-function(cpv) {
    substr(cpv,1,3)
  }
  
  subset[,1]<-sapply(subset[,1],getyear)
  subset[,3]<-sapply(subset[,3],getcpv3)
  
  uniquekey<-apply(subset,1,paste0,collapse="_")
  nbawards<-tapply(uniquekey,uniquekey,length)
  
  i.select<-which(nbawards>50 & nbawards<500)
  set.seed(2)
  
  splitID<-function(id) {strsplit(id,'_')[[1]]}
  datakeep<-ldply(names(nbawards[i.select]),splitID)
  
  match.cpv<-match(datakeep[,3],cpv[,1])
  i.rem<-which(is.na(match.cpv))
  datakeep<-datakeep[-i.rem,]
  match.cpv<-match.cpv[-i.rem]
  
  countries<-unique(datakeep[,2])
  
  nbc<-tapply(datakeep[,2],datakeep[,2],length)
  i.rem<-c()
  for (i in 1:length(countries)) {
    if (nbc[countries[i]]<5) i.rem<-c(i.rem,which(datakeep[,2]==countries[i]))
  }
  datakeep<-datakeep[-i.rem,]
  match.cpv<-match.cpv[-i.rem]
  i.order<-sort(datakeep[,2],index=T)$ix
  datakeep<-datakeep[i.order,]
  match.cpv<-match.cpv[i.order]
 
  countries<-sort(countries)  
  onestringcountries<-paste0("'",paste0(countries,collapse="','"),"'")
  nbAwardCountry<-tapply(datakeep[,2],datakeep[,2],length)
  onestringSize<-paste0(nbAwardCountry,collapse=",")
  offsetCountry<-c(1,1+as.numeric(cumsum(nbAwardCountry))[-length(nbAwardCountry)])
  onestringOffset<-paste0(offsetCountry,collapse=",")
  
  query.text<-paste0(cpv[match.cpv,2]," in ",datakeep[,2]," in ",datakeep[,1])
  onestring<-paste0("'",paste0(query.text,collapse="','"),"'")
  
  
  query.sql<-paste0("contracting_authority_country ='",datakeep[,2],
                    "' AND CPV_code LIKE('",datakeep[,3],
                    "%') AND official_journal_date >= '",datakeep[,1],
                    "-01-01' AND official_journal_date <= '",datakeep[,1],
                    "-12-31'")
  write.table(file="queries.sql",query.sql,col.names=F,row.names=F)
  
  queries<-list()
  for (i in 1:nrow(datakeep)) {
    queries<-c(queries,list(list(
    condition= 'AND',
    rules=list(list(
      id= 'contracting_authority_country',
      operator= 'equal',
      value= datakeep[i,2]
    ),
    list(
      id= 'CPV_code',
      operator= 'begins_with',
      value= datakeep[i,3]
    ),
    list(
      id= 'official_journal_date',
      operator= 'greater_or_equal',
      value= paste0(datakeep[i,1],'-01-01')
    ),
    list(
      id= 'official_journal_date',
      operator= 'less_or_equal',
      value= paste0(datakeep[i,1],'-12-31')
    )
    ))))
  }
  save(file="queries.sql",queries,query.sql)
  
}


