getCPVTable<-function() {
  
  data<-read.csv("CPVmeaning.csv",header=F,sep=";")
  write.table(file="CPVmeaning.csv",data,col.names=F,row.names=F,quote=F,sep=";")
  
  
}

convertCPV2003_2007<-function() {
  
  data<-read.csv("../Correspondance_2003-2007_en.csv",header=T,sep=";")
  data<-data[-which(data[,1]==""),c(1,3)]
  write.table(file="../code/data/CPVcorrespondance2003_2007.csv",data,col.names=F,row.names=F,quote=F,sep=";")
  
  
}

#This create the filter specifications for the query builder in the interface
#To be run if the DB schema changes
createFilters<-function() {
  
  column_info<-collect(sql(paste0("describe ",TED_TABLE)))
  
  #Countries
  column_info[which(column_info[,1]=='Contracting_Authority_Country'),2]<-'factor'
  column_info[which(column_info[,1]=='Contractor_Country'),2]<-'factor'
  
  column_info[which(column_info[,1]=='ID_TYPE'),2]<-'factor'
  column_info[which(column_info[,1]=='XSD_VERSION'),2]<-'factor'
  column_info[which(column_info[,1]=='CANCELLED'),2]<-'factor'
  column_info[which(column_info[,1]=='CORRECTIONS'),2]<-'factor'
  
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
               operators=list('equal','not_equal','contains', 'in', 'not_in','begins_with', 'ends_with','is_null', 'is_not_null')),
             factor={
               values<-sort(collect(sql(paste0("select distinct ",column_info[i,1]," from ",TED_TABLE)))[,1])
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
               operators=list('equal','not_equal','less', 'less_or_equal', 'greater','greater_or_equal','between','is_null', 'is_not_null')),
             bigint=list(
               id= column_info[i,1],
               label= column_info[i,1],
               type= 'integer',
               default_value="",
               operators=list('equal','not_equal','less', 'less_or_equal', 'greater','greater_or_equal','between','is_null', 'is_not_null')),
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


