#This script loads the data from TED database (CSV exported to SQLite database - see preprocessing.R), 
#and stores a subset of in session data 

#Create session data
sessionData <- reactiveValues()

#Get relevant data from TED DB
con <- dbConnect(RSQLite::SQLite(), "../TED_curated_contracts.db")
rs<-dbSendQuery(con,"select document_oj_date,contract_doc_no,contract_authority_country, contract_authority_official_name, contract_operator_country, contract_operator_official_name,contract_contract_value_cost_eur,document_award_criteria,contract_cpv_code from contracts where contract_contract_value_cost_eur>0")
data = fetch(rs, n=-1)
dbClearResult(rs)
dbDisconnect(con)

#Get countries infos
countries<-c("All",sort(unique(data[,'contract_authority_country'])))

#Store in session data
sessionData$alldata<-data
sessionData$data<-data
