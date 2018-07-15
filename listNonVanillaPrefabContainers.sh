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

set -u

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
  #sel -t -m //block[property[@class=UpgradeBlock and property[@name=ToBlock][@value=//block[property[@name=LootList]]/@name]]] -v @name -n blocks.xml 
  #sel -t -m //block[property[@name=DowngradeBlock][@value=//block[property[@name=LootList]]/@name]] -v @name -n blocks.xml
  xmlstarlet sel -t -m / -o "[" -m '//block[property[@name="LootList"] or property[@name="Extends"]/@value=//block[property[@name="LootList"]]/@name or property[@class="UpgradeBlock" and property[@name="ToBlock"][@value=//block[property[@name="LootList"]]/@name]] or property[@name="DowngradeBlock"][@value=//block[property[@name="LootList"]]/@name]]' -o '"' -v @id -o '"' --if "not(position()=last())" -o ", " -b -b -o "]" -n blocks.xml
}

LOOTABLE_BLOCKS="$(lootableBlocks)"

isLootable() {
  jq --argjson lootable "${LOOTABLE_BLOCKS}" 'map(select(.Id as $blockId | $lootable|map(.==$blockId)|any))'
}

vanillaPrefabs() {
  (cd "/mnt/c/Program Files (x86)/Steam/steamapps/common/7 Days To Die/Data/Prefabs";  ls -1)
}

VANILLA_PREFABS="$(vanillaPrefabs)"

declare prefabList
declare -A prefabs
prefabList="["

while read prefab
do
  echo "$VANILLA_PREFABS" | grep -q -x "${prefab}.xml" && continue

  RWG=$(rwgInfo "$prefab")
  [[ -z "$RWG" ]] && continue

  LIST=$(consoleCommand "bc-prefab blockcount \"$prefab\"" | jq ".Blocks" | isLootable)
  [[ $(echo "$LIST" | jq length) -gt 0 ]] || continue

  COUNT=$(echo "$LIST" | jq -r '{ "Prefab": "'"$prefab"'", "Count": (map(.Count) | add) }')

  if [[ $prefabList == "[" ]]
  then
    prefabList+="$COUNT"
  else
    prefabList+=",$COUNT"
  fi

  prefabs[$prefab]="$LIST"
done < <(consoleCommand "bc-prefab list" | jq -r ".Prefabs[]")

prefabList+="]"

while read prefabInfo
do
  prefab=$(echo $prefabInfo | jq -r .Prefab)
  count=$(echo $prefabInfo | jq .Count)
  echo "$prefab: $count containers"
  echo "${prefabs[$prefab]}" | jq --compact-output "sort_by(.Count) | reverse[]" | sed "s/^/    /"
  echo
done < <(echo "$prefabList" | jq --compact-output 'sort_by(.Count) | reverse[]')

set + u

# vim: et:ts=2:sw=2
