PuertoVigoShipMovs - Scraping
==========================================

Description
-----------

*PuertoVigoShipMovs* is a free software ruby application used to scrape the information from the [Vigo Harbour][1]

In order to extract the information the following steps are needed executed in the following order.

1.- manually adquire the html that shows the list of ships that have passed by the Vigo Harbour. 
In order to do that connect with the [list service][2] go to "Históricos/Históricos de buques"
enter the desired dates and no information on the shipName field then hit "Enviar".
Once the page has fully loaded save the frame containing the links as a html page to your hard drive 
(name it: AAAA_MM_DD_ShipList.html) in the ../html folder

2.- execute processShipList - (extracts the information from the html to a CSV style text file containing pairs "shipName,shipCod")
input: html page extracted from the previous step inside the ../html folder.
output: shipList.txt document on the ../txt folder
logs: information regarding warnings or unexpected results are stored in ../logs

3.- execute scrapeShipPortsOfCall - (scrapes the Vigo Harbour ship movements pages)
input: txt file extracted from the previous step inside the ../txt folder
output: html pages stored in the ../html_stops folder
logs: information regarding warninng or unexpected results are stored in ../logs

4.- execute processShipPortsOfCall - (processes the ship movements pages extracting the stops of each ship)
input: html pages stored in the ../html_stops folder
output: txt file (shipPortsOfCall.txt) stored in the ../txt folder
logs: information regarding warninng or unexpected results are stored in ../logs

5.- execute scrapeShipDockingInfo - (scrapes the Vigo Harbour ship docking pages)
input: txt file extracted from the previous step inside the ../txt folder
output: html pages stored in the ../html_docks folder
logs: information regarding warninng or unexpected results are stored in ../logs

6.- execute processShipDockingInfo - (processes the ship docking pages extracting the detailed information)
input: html pages stored in the ../html_docks folder
output: 3 csv files stored in the ../csv folder
  -shipData.csv: contains information about the ship
  -dockData.csv: contains information about the docking status (date, origin, destination,...)
  -operData.csv: contains information about the operation done while docked.
logs: information regarding warninng or unexpected results are stored in ../logs

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
