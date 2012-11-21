PuertoVigoShipMovs - DBupdate -
==========================================

Description
-----------

*PuertoVigoShipMovs* is a free software ruby application used to scrape and store the information from the [Vigo Harbour][1]

In order to extract and update the information DB the following steps are needed executed in the following order.

1.- execute extractDimFiles.rb - (extracts the Dimensions information from the csv files)
input: txt files extracted from the scraping job ../txt
output: txt files for the update in each dimension table ../updateDim

2.- execute updateDimDB.rb - (updates the information regarding dimension tables in the DB)
input: txt files for update ../updateDim
output: update in the mysql DB and delete the update text files

3.- execute extractDataFiles.rb - (extract the Data information from the csv files)
input: txt files extracted from the scraping job ../txt
output: txt files for the update in each data table ../updateData

4.- execute updateDataDB.rb - (updates the information regarding data tables in the DB)
input: txt files for update ../updateData
output: update in the mysql DB and delete the update text files

Requirements
------------

*You need the have a running version of ruby in your computer (only tested on ruby 1.9.3p194 but it should work in older versions, if it doesn't please report a bug) 

Reporting bugs
--------------

Please use the issue [reporting tool in github][4]

License
-------

*PuertoVigoShipMovs* is released under the terms of the [Apache License version 2.0][3].

Please read the ``LICENSE`` file for details.

Authors
-------

Please see ``AUTHORS`` file for more information about the authors.



[1]: http://www.apvigo.com
[2]: http://gis.portel.es/aplicaciones/gisweb/giswebport/frames.asp?AutPor=26
[3]: http://www.apache.org/licenses/
[4]: https://github.com/jjelosua/PuertoVigoShipMovs/issues
