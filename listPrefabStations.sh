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

workstationBlocks() {
  xmlstarlet sel -t -m / -o "[" -m '//block[property[@class="Workstation"] or property[@name="Extends"]/@value=//block[property[@class="Workstation"]]/@name]' -o '"' -v @id -o '"' --if "not(position()=last())" -o ", " -b -b -o "]" -n blocks.xml
}

workstation_BLOCKS="$(workstationBlocks)"

isWorkstation() {
  jq --argjson workstation "${workstation_BLOCKS}" 'map(select(.Id as $blockId | $workstation|map(.==$blockId)|any))'
}

consoleCommand "bc-prefab list" | jq -r ".Prefabs[]" | while read prefab
do
  LIST=$(consoleCommand "bc-prefab blockcount \"$prefab\"" | jq ".Blocks" | isWorkstation | jq --compact-output .[])
  if [[ -n "$LIST" ]]
  then
    echo "Prefab $prefab"
		#rwgInfo "$prefab"
    echo $LIST
  fi
done

# vim: et:ts=2:sw=2
