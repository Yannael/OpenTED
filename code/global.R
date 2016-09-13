#This script loads the data from TED database (CSV exported to Parquet files)

library(shiny)
library(queryBuildR)
library(markdown)
library(DT)
library(networkD3)
library(htmlwidgets)

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
sparkR.session(master="local[4]",sparkEnvir=sparkEnvir)

if (!file.exists("/tmp/spark-events")) {
  dir.create("/tmp/spark-events")
}

TED_TABLE<-"ted"

df <- read.df("ted.parquet", "parquet")
createOrReplaceTempView(df, TED_TABLE);

loadDataParquet<-function(sql) {
  withProgress(min=1, max=4, expr={
    setProgress(message = 'Computing statistics, please wait...',
                value=2)
  if (sql!="") sql<-paste0("where ",sql)
  nbrows<-collect(sql(paste0("select count(*) from ",TED_TABLE," ",sql)))
  limit<-""
  nbRowsErrorMessage<-""
  if (nbrows>1000) {
    limit<-" limit 1000"
    nbRowsErrorMessage<-paste0("Note: Your query returns ",nbrows," records. Only the first 1000 were retrieved. Refine selection with filters for a more focused set of results.")
  }
  setProgress(message = 'Retrieving data, please wait...',
              value=3)
  data<-collect(sql(paste0("select * from ",TED_TABLE," ",sql,limit)))
  })
  list(data=data,nbRowsErrorMessage=nbRowsErrorMessage)
}

load('data/filters.Rdata')
initFilters<-filters

load("queries.sql")


