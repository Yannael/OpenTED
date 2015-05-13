#### Overview

* This interface allows to more easily search the [TED (Tender Electronic Daily)](http://ted.europa.eu/) database of European public procurements.

* Data are from [OpenTED](http://ted.openspending.org/), for the period 2012-01-31 / 2015-02-27. By default, it retrieves all data for the period 2015-01-01 / 2015-02-27. You can change this (and other fields) using the filter checkbox.

#### Usage

#### Notes

* There are 1,5 million notices in total. If you select the whole range of data, you may need to wait a long time for the page to refresh. The average seems to be 1 second to retrieve 25000 records (i.e. 1 minute for all the records). Don't click several times on the 'apply' button, be patient ;)

* There are missing data in the award notices, and even erroneous data. This is independent of OpenTED data. To the best of our knowledge, data are the same as those available from the official TED EU site. Let us know if you spot any inconsistencies.

#### Code

* The interface was developed following the hackathon and discussions at the [European Investigative Journalism Conference (EIJC) 2015](http://www.journalismfund.eu/EIJC15).

* It is implemented in Shiny/R, and the code is open source and available on [Github](https://github.com/Yannael/OpenTED). 

#### Acknowledgments

* [OpenTED](http://ted.openspending.org)
* [EIJC](http://www.journalismfund.eu/EIJC15)

#### Design/Implementation

* [Yann-Aël Le Borgne](http://www.ulb.ac.be/di/map/yleborgn/)





