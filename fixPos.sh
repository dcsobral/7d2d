#!/usr/bin/env bash

if [[ $# < 3 ]]
then
	cat <<-EOF
		Syntax:
		$0 map-size world-dir prefabs-dir

		Example:
		$0 8192 "Data/Worlds/Hazeja Mountains" Data/Prefabs
	EOF
	exit 1
fi

SIZE=$1
WORLD="$2"
PREFABS="$3"
DIM="${1}x${1}"
ADJ=$(($SIZE / 2))

IFS='
'
for line in $(< "${WORLD}/prefabs.xml")
do
        coord=$(echo "$line" | grep position | cut -d '"' -f 6)
	if [[ -n "$coord" ]]
	then
		X=${coord%%,*}
		Z=${coord##*,}
		AX=$(($ADJ + $X))
		AZ=$(($ADJ + $Z))
		Y=$(convert -size $DIM -depth 16 "gray:${WORLD}/dtm.raw" -crop "1x1+${AX}+${AZ}" -depth 8 txt:- | tail -1 | cut -d '(' -f 3 | cut -d ')' -f 1)
		prefab=$(echo "$line" | cut -d '"' -f 4)
		YOffset=$(xmlstarlet sel -t -m "//property[@name='YOffset']" -v @value "${PREFABS}/${prefab}.xml")
		AY=$(($Y+$YOffset+1))
		echo "$line" | sed "s/$coord/$X,$AY,$Z/"
	else
		echo "$line"
	fi
done

