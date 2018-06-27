#!/bin/bash

# Requirements:
#
# * jq
# * xmlstarlet
# * curl
# * allocs server fixes
# * BadCompanySM
# * BadCompanySM-WebUI
#
# Must be run inside Data/Config directory, talks to server on localhost.
#
# At the very least the script should be edited to add the user and password tokens.
#
# xmlstarlet can be replaced by other tools capable of xpath queries.

consoleCommand() {
  curl  --data-urlencode "command=$1" -s --get -s "http://localhost:8082/api/executeconsolecommand?adminuser=user&admintoken=password" | jq ".result|fromjson"
}

prefabCount() {
  xmlstarlet sel -t -m "/" -v "count(//*[@name='$1'])" -n rwgmixer.xml
}

rwgInfo() {
  xmlstarlet sel -t -m "//*[@name='$1']" -m "ancestor::*" -v "name(.)" -m "@*" -o " " -v "name(.)" -o "=" -v "." -b -o "/" -b -v "name(.)" -m "@*" -o " " -v "name(.)" -o "=" -v "." -b -n rwgmixer.xml  
}

LOOTABLE_BLOCKS='["1747","1748","1740","1741","1742","1743","1744","1745","1717","1718","1719","1720","1721","1722","1078","1079","1080","1081","1922","1923","68","69"]'

isLootable() {
  jq --argjson lootable "${LOOTABLE_BLOCKS}" 'map(select(.Id as $blockId | $lootable|map(.==$blockId)|any))'
}

consoleCommand "bc-prefab list" | jq -r ".Prefabs[]" | while read prefab
do
  LIST=$(consoleCommand "bc-prefab blockcount \"$prefab\"" | jq ".Blocks" | isLootable | jq --compact-output .[])
  if [[ -n "$LIST" ]]
  then
    echo "Prefab $prefab"
    echo $LIST
  fi
done

# vim: et:ts=2:sw=2
