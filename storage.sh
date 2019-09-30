#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

craftableStorage() {
	if [[ -n ${1:-} ]]; then
		COND="[@name='$1']"
	else
		COND="[property[@name='Class'][@value='SecureLoot' or @value='Loot' or @value='DynamicStorageBoxSecure, Mods']][@name=\$r//recipe/@name]"
	fi

	xmlstarlet sel -t -m / \
		-m "str:split('',',')" -b \
		--var "r=document('recipes.xml')" \
		--var "l=document('loot.xml')" \
		-m "//block${COND}" \
			-v @name \
			-o "," \
			-m "\$l//lootcontainer[@id=current()/property[@name='LootList']/@value]" \
				--var "x=str:split(@size,',')" \
				-v "\$x[1] * \$x[2]" \
			-b \
			-o "," \
			-v "@name=drop[@event='Destroy']/@name" \
			-o "," \
			-v "'true'=property[@name='CanPickup']/@value" \
			-o "," \
			-v "contains(\$r//recipe[@name=current()/@name]/@tags,'learnable')" \
			-n blocks.xml
}

perk() {
     xmlstarlet sel -t \
		 -m "//passive_effect[@name='RecipeTagUnlocked'][contains(@tags,'${1}')]" \
			 -m "ancestor::*[name()='attribute' or name()='perk']" \
				-v @name \
				-o "," \
				-v "@base_skill_point_cost=0" \
			-b \
			-o "," \
			-v @level progression.xml || :
}

locked() {
	PERK="$(perk "$1")"
	IFS=',' read pernName schematic perkLevel <<<"$PERK"

	if [[ $2 == "true" ]]; then
		if [[ $schematic == "true" ]]; then
			echo "[S]"
		elif [[ -n $perkLevel ]]; then
			echo "[$perkLevel]"
		else
			echo "?"
		fi
	elif [[ -n $perkLevel ]]; then
		echo '[!]'
	fi
}

getStorage() {
	mapfile -t < <(craftableStorage)

	for f in "${MAPFILE[@]}"; do
		IFS=',' read n s d p l <<<"$f"
		while [[ -z $s ]]; do
			: "${_n:=$n}"
			parentName="$(xmlstarlet sel -t -m "//block[@name='$_n'][1]/property[@name='Extends'][1]" -v @value blocks.xml)"
			parentStats="$(craftableStorage "$parentName")"
			IFS=',' read _n s _d _p <<<"$parentStats"
		done
		N="$(grep "^$n," Localization.txt | csvtool format "%5" - || :)"
		D="$(if [[ $d == "true" ]]; then echo "*"; else echo ""; fi)"
		P="$(if [[ $p == "true" ]]; then echo \!; else echo ""; fi)"
		LOCK="$(locked "$n" "$l")"
		printf "%2d %s%s%s%s\n" "$s" "${N:-$n}" "$LOCK" "$D" "$P"
	done
}

if [[ -t 1 ]]; then
	getStorage | sort -n | column
else
	getStorage
fi

# vim: set ts=4 sw=4 tw=100 noet :
