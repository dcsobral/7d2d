# DCS 7 Days to Die Modder Projects

This is a collection of small projects I'm doing related to the modding of the game 7 Days to Die. Or it will be 
a collection, once I put other stuff here!

For now:

* [Ravenhearst's Food&Drinks Table](food.html) - A nice interactive table, generated from 7d2d's XML by
* [Food&Drinks Table Generator](foodPlus.xsl) - An XSLT that generates the above table automatically from items.xml
* [Medieval Tower Prefab](xcostum_medieval_tower/) - A prefab for 7d2d; better grab it from git

All XSLTs provided are XSLT 1.0 with EXSLT extensions (such as provided by libxml2 or xmlstarlet). They should be run
from the same directory as the configuration files, since they'll usually read other configuration file. If "Localization.xml"
is required, you can either create a mostly empty xml file (Just ```<xml/>``` should suffice), or use something
to convert the text (csv, actually) file to an XML. I adapted something from the internet using perl: [csv2xml.pl](csv2xml.pl).
You can even just copy one of the other xml files to "Localization.xml" -- you won't get the localized text, but it should
otherwise work.

