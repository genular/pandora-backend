#!/usr/bin/env bash

# NOTE:
# This uses your \`.netrc\` file to authenticate with GitHub. In order to run the
# script, make sure you have **both** \`api.github.com\` and \`upload.github.com\` in
# this file. For example:
# machine api.github.com
#   login foca
#   password <an access token>
# machine upload.github.com
#   login foca
#   password <an access token>
# Generate this access token at https://github.com/settings/tokens and make sure
# it has access to the \`"repo"\` scope.
# 

# https://developer.github.com/v3/repos/releases/#create-a-release
tag_name="v0.1.0" # Required. The name of the tag.
target_commitish="master" # Specifies the commitish value that determines where the Git tag is created from. 
name="" # The name of the release.
body=""
draft=true
prerelease=true
ASSETS=()

repos=( "genular/simon-frontend" "genular/simon-backend" )

for repo in "${repos[@]}"
do
	name="$tag_name";
	# jq is a tool for processing JSON inputs
	payload=$(
	  jq --null-input \
	     --arg tag_name "$tag_name" \
	     --arg target_commitish "$target_commitish" \
	     --arg name "$name" \
	     --arg body "$body" \
	     --argjson draft "$draft" \
	     --argjson prerelease "$prerelease" \
	     '{ tag_name: $tag_name, target_commitish: $target_commitish, name: $name, body: $body, draft: $draft, prerelease: $prerelease }'
	)
	echo "Creating github release with following parameters: $payload"

	response=$(
	  curl --fail \
	       --netrc \
	       --silent \
	       --location \
	       --data "$payload" \
	       "https://api.github.com/repos/${repo}/releases"
	)

	upload_url="$(echo "$response" | jq -r .upload_url | sed -e "s/{?name,label}//")"

	for file in $ASSETS; do
		echo "Adding $file from assets\r\n"
		curl --netrc \
			--header "Content-Type:application/gzip" \
			--data-binary "@$file" \
			"$upload_url?name=$(basename "$file")"
	done
done
