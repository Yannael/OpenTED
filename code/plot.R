#This plots the graph of Fig. 1 in the article 'OpenTED Browser: Insights into European Public spendings'
#SQL connection needs  to be open first, see global.R script
data<-collect(sql(sqlContext,paste0("select count(YEAR),YEAR,Contracting_Authority_Country from ",TED_TABLE," group by YEAR,Contracting_Authority_Country")))
colnames(data)[1]<-'count'

#Aggregate data for category 'other'
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

#Reorder by number of notices/country
DF[,1]<-as.numeric(DF[,1])
DF[,2]<-as.factor(DF[,2])
DF[,3]<-as.factor(DF[,3])

orderCountry<-names(rev(sort(tapply(DF[,1],DF[,3],sum))))
DF[,3]<-factor(DF[,3],levels=orderCountry)

ggplot(DF, aes(YEAR, fill=Contracting_Authority_Country,weight=count)) + 
  geom_bar() +
  scale_fill_brewer(palette="Set1",name="Contracting authority country") +
  xlab("Year") +
  ylab("Number of contract award notices")

