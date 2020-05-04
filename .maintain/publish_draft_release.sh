#!/usr/bin/env bash

# shellcheck source=lib.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/lib.sh"

version="$CI_COMMIT_TAG"

# Note that this is not the last *tagged* version, but the last *published* version
last_version=$(last_github_release 'paritytech/polkassembly')
release_text="$(GITHUB_RELEASE_TOKEN="$GITHUB_RELEASE_TOKEN" ./.maintain/generate_changelog.sh "$last_version" "$version")"

echo "[+] Pushing release to github"
# Create release on github
release_name="Polkassembly $version"
data=$(jq -Rs --arg version "$version" \
  --arg release_name "$release_name" \
  --arg release_text "$release_text" \
'{
  "tag_name": $version,
  "target_commitish": "master",
  "name": $release_name,
  "body": $release_text,
  "draft": true,
  "prerelease": false
}' < /dev/null)

out=$(curl -s -X POST --data "$data" -H "Authorization: token $GITHUB_RELEASE_TOKEN" "$api_base/paritytech/polkassembly/releases")

html_url=$(echo "$out" | jq -r .html_url)

if [ "$html_url" == "null" ]
then
  echo "[!] Something went wrong posting:"
  echo "$out"
else
  echo "[+] Release draft created: $html_url"
fi

# echo '[+] Sending draft release URL to Matrix'

# msg_body=$(cat <<EOF
# **Release pipeline for Polkassembly $version complete.**
# Draft release created: $html_url
# EOF
# )
# formatted_msg_body=$(cat <<EOF
# <strong>Release pipeline for Polkassembly $version complete.</strong><br />
# Draft release created: $html_url
# EOF
# )

echo "[+] Done! Maybe the release worked..."