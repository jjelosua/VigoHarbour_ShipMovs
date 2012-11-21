# ************************************************************
# Sequel Pro SQL dump
# Version 3408
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.5.25a)
# Database: APVigo_ShipMovs
# Generation Time: 2012-11-21 12:01:54 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table DAT_DOCK
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_DOCK`;

CREATE TABLE `DAT_DOCK` (
  `id` int(8) NOT NULL,
  `shipId` int(6) NOT NULL,
  `stop` text,
  `bollards` text,
  `quay` text,
  `dockArrival` datetime NOT NULL,
  `dockDeparture` datetime NOT NULL,
  `consigneeId` int(3) NOT NULL,
  `originPlaceId` int(6) NOT NULL,
  `originCountryId` int(3) NOT NULL,
  `destinationPlaceId` int(6) NOT NULL,
  `destinationCountryId` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DAT_OPER
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_OPER`;

CREATE TABLE `DAT_OPER` (
  `id` int(6) NOT NULL,
  `shipId` int(6) NOT NULL,
  `dockId` int(8) NOT NULL,
  `operSec` int(3) NOT NULL,
  `operTypeId` int(3) NOT NULL,
  `operTypeDesc` text,
  `tons` int(8) DEFAULT NULL,
  `merchandiseId` int(3) NOT NULL,
  `longshoreId` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DAT_SHIP
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_SHIP`;

CREATE TABLE `DAT_SHIP` (
  `id` int(6) NOT NULL,
  `shipName` text NOT NULL,
  `shipLength` float DEFAULT NULL,
  `shipWidth` float DEFAULT NULL,
  `shipDraught` float DEFAULT NULL,
  `shipGrossTonnage` int(8) DEFAULT NULL,
  `shipTypeId` int(3) NOT NULL,
  `shipFlagId` int(3) NOT NULL,
  `shipCode` text NOT NULL,
  `shipLLoyds` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_CONSIGNEE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_CONSIGNEE`;

CREATE TABLE `DIM_CONSIGNEE` (
  `id` int(3) NOT NULL,
  `consigneeName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_COUNTRY
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_COUNTRY`;

CREATE TABLE `DIM_COUNTRY` (
  `id` int(3) NOT NULL,
  `countryName` text NOT NULL,
  `valid` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_DOCKID
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_DOCKID`;

CREATE TABLE `DIM_DOCKID` (
  `id` int(8) unsigned NOT NULL,
  `dockCode` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_LONGSHORE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_LONGSHORE`;

CREATE TABLE `DIM_LONGSHORE` (
  `id` int(3) NOT NULL,
  `longshoreName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_MERCHANDISE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_MERCHANDISE`;

CREATE TABLE `DIM_MERCHANDISE` (
  `id` int(3) NOT NULL,
  `merchandiseName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_OPERTYPE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_OPERTYPE`;

CREATE TABLE `DIM_OPERTYPE` (
  `id` int(3) NOT NULL,
  `operTypeCode` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_PLACE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_PLACE`;

CREATE TABLE `DIM_PLACE` (
  `id` int(6) NOT NULL,
  `placeName` text NOT NULL,
  `valid` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_SHIPID
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_SHIPID`;

CREATE TABLE `DIM_SHIPID` (
  `id` int(6) unsigned NOT NULL,
  `shipCode` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_SHIPTYPE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_SHIPTYPE`;

CREATE TABLE `DIM_SHIPTYPE` (
  `id` int(3) NOT NULL,
  `shipType` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
