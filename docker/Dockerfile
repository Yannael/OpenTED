#Dockerfile for OpenTED browser. Maintainer: Yann-Aël Le Borgne - yleborgn@ulb.ac.be
FROM rocker/shiny

#Install Java
RUN apt-get update 
RUN apt-get install -y openjdk-8-jdk

#Necessary to install rJava
RUN R CMD javareconf

#Install packages for MySQL, SSL, git and nano, SSH. net-tools and whois required for SSH
RUN apt-get -y install libmysqlclient-dev libxml2-dev libssl-dev git nano openssh-server  net-tools whois man 

RUN echo shiny:shiny | chpasswd
USER shiny

ENV HOME /home/shiny
WORKDIR $HOME

#Install Spark
#Precompiled with : mvn -Pyarn -Phadoop-2.6 -Dhadoop.version=2.6.0 -Dyarn.version=2.6.0 -DskipTests -Dscala-2.11 -Phive -Phive-thriftserver clean package
RUN wget http://litpc45.ulb.ac.be/spark161_2.11_SparkR.tgz
RUN tar xvzf spark161_2.11_SparkR.tgz

ENV SPARK_HOME $HOME/spark

USER root

RUN R -e "install.packages(c('shiny','markdown','DT','htmlwidgets','devtools'), repos='http://cran.rstudio.com/')"
RUN R -e "devtools::install_github('yannael/networkD3')"
RUN R -e "devtools::install_github('yannael/queryBuildR')"

#Startup script to start Shiny server
ADD startupscript.sh /usr/bin/startupscript.sh
