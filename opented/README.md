#### Overview

* This interface allows to more easily search the [TED (Tender Electronic Daily)](http://ted.europa.eu/) database of European public procurements.

* Data are from [OpenTED](http://ted.openspending.org/), for the period 2012-01-31 / 2015-02-27. By default, it retrieves all data for the period 2015-01-01 / 2015-02-28. You can change this (and other fields) using the filter checkbox.

#### Notes

* There are 1,5 million notices in total. Due to server limits, the maximum number of notices you can retrieve in a query is 500000. You will be notified by a warning message if your query exceeds this limits.

* There are missing data in the award notices, and even erroneous data. This is independent of OpenTED data. To the best of our knowledge, data are the same as those available from the official TED EU site. Let us know if you spot any inconsistencies.

#### Code

* The interface was developed following the hackathon and discussions at the [European Investigative Journalism Conference (EIJC) 2015](http://www.journalismfund.eu/EIJC15).

* It is implemented in Shiny/R, and the code is open source and available on [Github](https://github.com/Yannael/OpenTED). 

#### Acknowledgments

* [OpenTED](http://ted.openspending.org)
* [EIJC](http://www.journalismfund.eu/EIJC15)

#### Design/Implementation

* [Yann-Aël Le Borgne](http://www.ulb.ac.be/di/map/yleborgn/)





