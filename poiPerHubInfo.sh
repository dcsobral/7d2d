#!/bin/bash

set -u

consoleCommand() {
  curl  --data-urlencode "command=$1" -s --get -s "http://localhost:8082/api/executeconsolecommand?adminuser=user&admintoken=password" | jq ".result|fromjson"
}

HCD=$(consoleCommand 'bc-hcd /r=6 /o=0,0 /full')
#HCD=$(cat allprefabs.txt)

read -r -d '' CMD <<-EOC
	{ "Index": .key }
	+ (.value
		| { GridPos, Township, CellRule, HubRule, WildernessRule }
		+ (.Lots
			| group_by(.LotType)
				| map ({(.[0].LotType): (
					group_by(.Prefab)
						|reverse
						|sort_by(length)
						|reverse
						|map({(.[0].Prefab): length})
					|add
				)})
			| add
		)
	)
EOC
cat <<EOC
EOC

echo "$HCD" | jq "to_entries|map($CMD)"

set +u

