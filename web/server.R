library(shiny)
library(RMySQL)
library(ggplot2)

shinyServer(function(input, output) {
  
  #Modify range of session data to display according to date range
  observe({
      if (length(input$dateRange)>0) {
        data<-sessionData$alldata
        to.keep<-which(sessionData$alldata[,'document_oj_date']>=input$dateRange[1] & sessionData$alldata[,'document_oj_date']<=input$dateRange[2])
        data<-data[to.keep,]
        sessionData$data<-data[sort(data[,'document_oj_date'],index.return=T)$ix,]
      }
  })
  
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
  
  #Returns the dataset in the form of a table, filtered by country
  output$awardTable<-renderDataTable({
    sessionData$data
    country<-input$selectAuthorityCountry
    #Only valid once a country is selected
    if (length(country)>0) {
      #Get data from session data, according to country selection
      if (country=="All")
        data<-sessionData$data
      else 
        data<-sessionData$data[which(data<-sessionData$data[,'contract_authority_country']==country),]
      
      #Let's columns have nice names
      colnames(data)<-c("Official journal date","Award notice ID","Contract authority country","Contract authority official name","Contractor country","Contractor official name","Contract value (EUR)","Award criteria","CPV code")
      
      #Create table and send it to UI
      data
    }
  },
  escape=F,#This so HTML links are properly rendered
  options=list(
    lengthMenu = list(c(10, 100, -1), c('10', '100','All')),pageLength = 10,
    autoWidth = FALSE
  )
  )
  
})
