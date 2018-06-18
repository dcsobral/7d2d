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

lootableBlocks() {
  xmlstarlet sel -t -m / -o "[" -m '//block[property[@name="LootList"] or property[@name="Extends"]/@value=//block[property[@name="LootList"]]/@name or property[@class="UpgradeBlock" and property[@name="ToBlock"][@value=//block[property[@name="LootList"]]/@name]] or property[@name="DowngradeBlock"][@value=//block[property[@name="LootList"]]/@name]]' -o '"' -v @id -o '"' --if "not(position()=last())" -o ", " -b -b -o "]" -n blocks.xml
}

LOOTABLE_BLOCKS="$(lootableBlocks)"

isLootable() {
  jq --argjson lootable "${LOOTABLE_BLOCKS}" 'map(select(.Id as $blockId | $lootable|map(.==$blockId)|any))'
}

consoleCommand "bc-prefab list" | jq -r ".Prefabs[]" | while read prefab
do
  if [[ $(prefabCount "$prefab") > 0 ]]
  then
    echo "Prefab $prefab"
    rwgInfo "$prefab"
    consoleCommand "bc-prefab blockcount \"$prefab\"" | jq ".Blocks" | isLootable | jq --compact-output .[]
  fi
done

# vim: et:ts=2:sw=2
