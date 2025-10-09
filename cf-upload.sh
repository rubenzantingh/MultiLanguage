#!/bin/sh

RELEASE_NAME="$1"
RELEASE_MESSAGE="$2"
GAME_VERSIONS=[13771]
FILE_PATH="./MultiLanguage.zip"

CF_METADATA=$(cat <<-EOF
{
    "displayName": "$RELEASE_NAME",
    "releaseType": "release",
    "changelog": "$RELEASE_MESSAGE",
    "changelogType": "markdown",
    "gameVersions": $GAME_VERSIONS,
}
EOF
)

response=$(curl -sS \
    -o response.txt \
    -w "%{http_code}" \
    -H "X-API-TOKEN: $CF_API_TOKEN" \
    -F "metadata=$CF_METADATA" \
    -F "file=@$FILE_PATH" \
    "https://wow.curseforge.com/api/projects/965777/upload-file")

http_status=$(echo "$response" | tail -n1)

if [ "$http_status" -eq 200 ]; then
  echo "CurseForge upload successful"
else
  echo "CurseForge upload failed, HTTP-code: $http_status"
  cat response.txt
  exit 1
fi
