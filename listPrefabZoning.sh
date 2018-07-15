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

declare -A zoning
declare -A bioming
declare -A townshipping

prefabList=""
zones=""
biomes=""
townships=""

while read prefab
do
  RWG=$(rwgInfo "$prefab")
  [[ -z "$RWG" ]] && continue

  prefabList+="${prefab}"$'\n'

  PROPS=$(consoleCommand "bc-prefab setprop ${prefab}")

  ZONING=$(echo "$PROPS" | jq -r '.Zoning // empty | split (",")[]')
  BIOMES=$(echo "$PROPS" | jq -r '.AllowedBiomes // empty | split (",")[]')
  TOWNSHIP=$(echo "$PROPS" | jq -r '.AllowedTownships // empty | split (",")[]')

  zones+="$ZONING"$'\n'
  biomes+="$BIOMES"$'\n'
  townships+="$TOWNSHIP"$'\n'

  zoning[$prefab]="$ZONING"
  bioming[$prefab]="$BIOMES"
  townshipping[$prefab]="$TOWNSHIP"
done < <(consoleCommand "bc-prefab list" | jq -r ".Prefabs[]")

zones=$(echo "$zones" | sort -u)
biomes=$(echo "$biomes" | sort -u)
townships=$(echo "$townships" | sort -u)

#set +u; return

while read zone
do
  [[ -z "$zone" ]] && continue
  echo -n "$zone,"
done < <(echo "$zones")

while read biome
do
  [[ -z "$biome" ]] && continue
  echo -n "$biome,"
done < <(echo "$biomes")

while read township
do
  [[ -z "$township" ]] && continue
  echo -n "$township,"
done < <(echo "$townships")

echo

while read prefab
do
  [[ -z "$prefab" ]] && continue

  echo -n "$prefab"

  while read zone
  do
    [[ -z "$zone" ]] && continue
    echo ${zoning[$prefab]} | grep -q $zone && echo -n ",true" || echo -n ",false"
  done < <(echo "$zones")

  while read biome
  do
    [[ -z "$biome" ]] && continue
    echo ${bioming[$prefab]} | grep -q $biome && echo -n ",true" || echo -n ",false"
  done < <(echo "$biomes")

  while read township
  do
    [[ -z "$township" ]] && continue
    echo ${townshipping[$prefab]} | grep -q $township && echo -n ",true" || echo -n ",false"
  done < <(echo "$townships")

  echo
done < <(echo "$prefabList")

set +u

# vim: et:ts=2:sw=2
