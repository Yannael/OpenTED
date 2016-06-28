library(shiny)
library(queryBuildR)
library(markdown)
library(DT)
library(networkD3)
library(htmlwidgets)

#This script loads the data from TED database (CSV exported to Parquet files), 
#and stores a subset of in session data 

CPVTable<-read.table("data/CPVTable.txt",stringsAsFactors=F,colClasses=c("character"))
colnames(CPVTable)<-c("Original code","CPV plain code","NUM-digits", "Real Code", "Category content")
levelsCPV<-levels(as.factor(CPVTable[,2]))

SPARK_HOME<-"/Users/yalb/spark"
#SPARK_HOME<-"/home/shiny/spark"
Sys.setenv(SPARK_HOME=SPARK_HOME)
Sys.setenv(PATH=paste0(SPARK_HOME,"/bin:",SPARK_HOME,"/sbin:",Sys.getenv("PATH")))

.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
library(SparkR)

sparkEnvir <- list('spark.sql.parquet.binaryAsString'='true') #Needed to read strings from Parquet
sc<-sparkR.init(master="local[4]",sparkEnvir=sparkEnvir)
sqlContext <- sparkRSQL.init(sc) 

if (!file.exists("/tmp/spark-events")) {
  dir.create("/tmp/spark-events")
}

TED_TABLE<-"ted"

df <- read.df(sqlContext, "ted.parquet", "parquet")
registerTempTable(df, TED_TABLE);

loadDataParquet<-function(sql) {
  withProgress(min=1, max=4, expr={
    setProgress(message = 'Computing statistics, please wait...',
                value=2)
  if (sql!="") sql<-paste0("where ",sql)
  nbrows<-collect(sql(sqlContext,paste0("select count(*) from ",TED_TABLE," ",sql)))
  limit<-""
  nbRowsErrorMessage<-""
  if (nbrows>1000) {
    limit<-" limit 1000"
    nbRowsErrorMessage<-paste0("Note: Your query returns ",nbrows," records. Only the first 1000 were retrieved. Refine selection with filters for a more focused set of results.")
  }
  setProgress(message = 'Retrieving data, please wait...',
              value=3)
  data<-collect(sql(sqlContext,paste0("select * from ",TED_TABLE," ",sql,limit)))
  })
  list(data=data,nbRowsErrorMessage=nbRowsErrorMessage)
}

load('data/filters.Rdata')
initFilters<-filters

load("queries.sql")

dummy<-function() {
  
  column_info<-collect(sql(sqlContext,paste0("describe ",TED_TABLE)))
  
  #Countries
  column_info[3,2]<-'factor'
  column_info[5,2]<-'factor'
  
  column_info[which(column_info[,1]=='ID_TYPE'),2]<-'factor'
  column_info[which(column_info[,1]=='XSD_VERSION'),2]<-'factor'
  column_info[which(column_info[,1]=='CANCELLED'),2]<-'factor'
  
  column_info[which(column_info[,1]=='CAE_TYPE'),2]<-'factor'
  column_info[which(column_info[,1]=='B_ON_BEHALF'),2]<-'factor'
  column_info[which(column_info[,1]=='TYPE_OF_CONTRACT'),2]<-'factor'
  column_info[which(column_info[,1]=='B_FRA_AGREEMENT'),2]<-'factor'
  column_info[which(column_info[,1]=='B_GPA'),2]<-'factor'
  column_info[which(column_info[,1]=='B_DYN_PURCH_SYST'),2]<-'factor'
  column_info[which(column_info[,1]=='TOP_TYPE'),2]<-'factor'
  column_info[which(column_info[,1]=='CRIT_CODE'),2]<-'factor'
  column_info[which(column_info[,1]=='B_ELECTRONIC_AUCTION'),2]<-'factor'
  column_info[which(column_info[,1]=='B_SUBCONTRACTED'),2]<-'factor'
  column_info[which(column_info[,1]=='B_EU_FUNDS'),2]<-'factor'
  
  column_info[which(column_info[,1]=='Dispatch_Date'),2]<-'date'
  column_info[which(column_info[,1]=='DT_AWARD'),2]<-'date'
  
  filters<-list()
  for (i in 1:nrow(column_info)) {
    filterCol<-
      switch(column_info[i,2],
             string=list(
               id= column_info[i,1],
               label= column_info[i,1],
               type= 'string',
               default_value="",
               operators=list('equal','not_equal','contains', 'less', 'less_or_equal', 'greater','greater_or_equal','between', 'in', 'not_in','begins_with', 'ends_with','is_null', 'is_not_null')),
             factor={
               values<-sort(collect(sql(sqlContext,paste0("select distinct ",column_info[i,1]," from ",TED_TABLE)))[,1])
               list(
                 id= column_info[i,1],
                 label= column_info[i,1],
                 type= 'string',
                 input='select',
                 values=values,
                 default_value=values[1],
                 operators=list('equal','not_equal','is_null', 'is_not_null'))
             },
             date=list(
               id= column_info[i,1],
               label= column_info[i,1],
               type= 'string',
               default_value="",
               operators=list('equal','not_equal','less', 'less_or_equal', 'greater','greater_or_equal','between','in', 'not_in','is_null', 'is_not_null')),
             int=list(
               id= column_info[i,1],
               label= column_info[i,1],
               type= 'integer',
               default_value="",
               operators=list('equal','not_equal','less', 'less_or_equal', 'greater','greater_or_equal','between','in', 'not_in','is_null', 'is_not_null')),
             double=list(
               id= column_info[i,1],
               label= column_info[i,1],
               type= 'double',
               default_value="",
               operators=list('equal','not_equal',  'less', 'less_or_equal', 'greater','greater_or_equal','between','is_null', 'is_not_null'))
      )
    filters<-c(filters,list(filterCol))
  }
  save(file="data/filters.Rdata",filters)
}

dummy<-function() {
  
  data<-collect(sql(sqlContext,paste0("select count(YEAR),YEAR,Contracting_Authority_Country from ",TED_TABLE," group by YEAR,Contracting_Authority_Country")))
  colnames(data)[1]<-'count'
  
  DF<-NULL
  for (year in 2006:2015) {
    dd<-data[which(data[,2]==year),]
    others<-0
    for (i in 1:nrow(dd)) {
      if (dd[i,1]>15000) DF<-rbind(DF,dd[i,])
      else others<-others+dd[i,1]
    }
    DF<-rbind(DF,c(others,year,'Other'))
  }
  
  orderCountry<-names(sort(tapply(DF[,1],DF[,3],sum)))
  
  DF[,1]<-as.numeric(DF[,1])
  DF[,2]<-as.factor(DF[,2])
  DF[,3]<-as.factor(DF[,3])
  
  orderCountry<-names(rev(sort(tapply(DF[,1],DF[,3],sum))))
  DF[,3]<-factor(DF[,3],levels=orderCountry)
  
  
  
  ggplot(DF, aes(YEAR, fill=Contracting_Authority_Country,weight=count)) + 
    geom_bar() +
    scale_fill_hue(name="Contracting authority country") +
    xlab("Year") +
    ylab("Number of contract award notices") 
  
  xlab("Number of samples") +
    ylab("Computation time") +
    scale_fill_hue(name="Number of variants")
  
}


