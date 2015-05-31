install.packages('RCurl')
install.packages('shiny')
install.packages('RMySQL')
install.packages('devtools')
devtools::install_github('rstudio/DT')
devtools::install_github('christophergandrud/networkD3')


wget http://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.4.0.708-amd64.deb
sudo gdebi shiny-server-1.4.0.708-amd64.deb
