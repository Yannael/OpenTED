#### Overview

* This interface allows to more easily search the [TED (Tender Electronic Daily)](http://ted.europa.eu/) database of European public procurements.
* Data are from [OpenTED](http://ted.openspending.org/), for the period 2012-01-31 / 2015-02-27. 

#### Online interface 

* (Temporary location. Will soon be relocated): [http://litpc45.ulb.ac.be/opented](http://litpc45.ulb.ac.be/opented)

#### Usage

* Once loaded, the interface returns award notices for all countries, for the period 2015-01-01 / 2015-02-28 (around 42000 notices).
* You may extend the period with the 'select period' widget (no notices before 2012-01-31 and after 2015-02-27)
* **Note** that the whole period 2012-01-31 / 2015-02-27 contains more than 1,5 million notices. While the interface is reasonably responsive for 100000 notices, it will obviously take some time (about 20 seconds) to load more than one million notices. 
* **Patience :)** If your selection is big, wait. Clicking again on 'Apply', or on table options, will end up taking twice the time, or bring error messages. You should however not wait more than 30 seconds...
* Once you loaded all the notices for the period you are interested in, you can use the filters (boxes above columns), and sorting (arrows above columns) tools.
* Filtering is fast, but sorting can be slow if many notices are selected (especially on character columns, see below).
* There are three types of filters, depending on the column:
 * Country columns (authority and contractor) allow you to select the set of countries you want to include
 * Number columns (contract value, number offers received, CPV code) allow you to select a range of values using sliders. You may also enter the range in the box by typing 'x ... y' (without '') where x and y are the imits of your interval. For example '10 ... 10000' in the contract value filtering box will select notices whose contract value is between 10 and 10000. Note that you may leave either 'x' or 'y' blank, so the interval is open. Thus '10 ...' will select notices whose contract value is higher than 10.
 * The other columns are 'character columns', meaning that their contents are treated as strings of characters. Notices will be selected if part of their content contains the text you typed in the filtering box. 
* The meaning of CPV codes is available in the 'CPV codes' tab.
* You can download your selection using the 'Download CVS/GEXF' button. This will download a ZIP file which contains two files:
 *  'selection.csv' is an export of the table in the CSV format,
 * 'networkGephi.gexf' is a file you can load in Gephi, to visualize the relationships between authorities and contrators in a network.
* Downloading your selection may take a long time. Expect instantaneous download for 100 notices, 30 seconds for 50000 notices, and minutes for more than 100000 notices. 
* There are missing data in the award notices, and even erroneous data. This is independent of OpenTED data. To the best of our knowledge, data are the same as those available from the official TED EU site. Let us know if you spot any inconsistencies.

#### Code

* The interface was developed following the hackathon and discussions at the [European Investigative Journalism Conference (EIJC) 2015](http://www.journalismfund.eu/EIJC15).
* It is implemented in Shiny/R, and the code is open source and available on [Github](https://github.com/Yannael/OpenTED). 

#### Acknowledgments

* [OpenTED](http://ted.openspending.org)
* [EIJC](http://www.journalismfund.eu/EIJC15)
* © European Union, [http://ted.europa.eu](http://ted.europa.eu), 1998–2015

#### Design/Implementation

* [Yann-Aël Le Borgne](http://www.ulb.ac.be/di/map/yleborgn/)





