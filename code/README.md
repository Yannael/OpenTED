#### Overview

* This interface allows to more easily search the [TED (Tender Electronic Daily)](http://ted.europa.eu/) database of European public procurements.
* Data are from [the European Union Open Data Portal](https://data.europa.eu/euodp/en/data/dataset/ted-csv), and span the period 2006-2015.
* Check the <a href="http://ulb.ac.be/di/map/yleborgn/pub/presentation/LeBorgne_ECML-SoGood2016_OpenTED.pdf" target="_blank">slides of the presentation</a> at <a href="https://sites.google.com/site/ecmlpkdd2016sogood/" target="_blank">ECML/PKDD SoGood 2016</a>.

#### Usage 

* Example: Select awards notices for construction work in Germany in 2014, with award values higher than 2 million euros. Click on thumbnail below to see tutorial video.
<br>
<a href="http://www.dailymotion.com/video/x30u8db_open-ted-browsing-interface" target="_blank"><img src="http://s2.dmcdn.net/M6gve/x240-iio.jpg" 
 width="480" height="360" border="10" align="center"/></a>

#### Online interface 

* [http://yleborgne.net/opented](http://yleborgne.net/opented)

#### History

* 2016/09/15: Import update of official TED data, 2006-2015 - Version 2.1 (http://data.europa.eu/euodp/repository/ec/dg-grow/mapps/TED(csv)_data_information.pdf) 
* 2016/07/04: Import of official TED data, 2006-2015 (https://data.europa.eu/euodp/en/data/dataset/ted-csv)
* 2015/08/01: Added query builder
* 2015/06/15: Added contract flows visualization
* 2015/05/15: Initial version

#### Code

* The interface was developed following the hackathon and discussions at the [European Investigative Journalism Conference (EIJC) 2015](http://www.journalismfund.eu/EIJC15) and [European Investigative Journalism Conference (EIJC) 2016](http://www.journalismfund.eu/EIJC16).
* It is implemented in Shiny/R, and the code is open source and available on [Github](https://github.com/Yannael/OpenTED). 

#### Acknowledgments

* [OpenTED](http://ted.openspending.org)
* [EIJC](http://www.journalismfund.eu/EIJC15)
* © European Union, [http://ted.europa.eu](http://ted.europa.eu), 1998–2016
* [BruFence: 'Scalable machine learning for automating defense system'](http://www.securit-brussels.be/project/brufence), a project funded by the Institute for the Encouragement of Scientific Research and Innovation of Brussels (INNOVIRIS, Brussels Region, Belgium)

#### Design/Implementation

* [Yann-Aël Le Borgne](https://www.linkedin.com/in/yannaelb) - [Machine Learning Group](http://mlg.ulb.ac.be) - [Université Libre de Bruxelles](http://ulb.ac.be) - Belgium 
