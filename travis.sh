#!/bin/bash
# Demyx
# https://demyx.sh
# https://github.com/peter-evans/dockerhub-description/blob/master/entrypoint.sh
IFS=$'\n\t'

# Get versions
DEMYX_OPENLITESPEED_DEBIAN_VERSION="$(docker exec -t demyx_wp cat /etc/debian_version | sed -e 's/\r//g')"
DEMYX_OPENLITESPEED_VERSION="$(docker exec -t demyx_wp cat /usr/local/lsws/VERSION | sed -e 's/\r//g')"
DEMYX_OPENLITESPEED_LSPHP_VERSION="$(docker exec -t demyx_wp sh -c '/usr/local/lsws/"$OPENLITESPEED_LSPHP_VERSION"/bin/lsphp -v' | head -1 | awk '{print $2}' | sed 's/\r//g')"

# Replace versions
sed -i "s|debian-.*.-informational|debian-${DEMYX_OPENLITESPEED_DEBIAN_VERSION}-informational|g" README.md
sed -i "s|${DEMYX_REPOSITORY}-.*.-informational|${DEMYX_REPOSITORY}-${DEMYX_OPENLITESPEED_VERSION}-informational|g" README.md
sed -i "s|lsphp-.*.-informational|lsphp-${DEMYX_OPENLITESPEED_LSPHP_VERSION//-/--}-informational|g" README.md

# Echo versions to file
echo "DEMYX_OPENLITESPEED_DEBIAN_VERSION=$DEMYX_OPENLITESPEED_DEBIAN_VERSION
DEMYX_OPENLITESPEED_VERSION=$DEMYX_OPENLITESPEED_VERSION
DEMYX_OPENLITESPEED_LSPHP_VERSION=$DEMYX_OPENLITESPEED_LSPHP_VERSION" > VERSION

# Push back to GitHub
git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"
git remote set-url origin https://${DEMYX_GITHUB_TOKEN}@github.com/demyxco/"$DEMYX_REPOSITORY".git
# Commit VERSION first
git add VERSION
git commit -m "DEBIAN $DEMYX_OPENLITESPEED_DEBIAN_VERSION, OPENLITESPEED $DEMYX_OPENLITESPEED_VERSION, LSPHP $DEMYX_OPENLITESPEED_LSPHP_VERSION"
git push origin HEAD:master
# Commit the rest
git add .
git commit -m "Travis Build $TRAVIS_BUILD_NUMBER"
git push origin HEAD:master

# Set the default path to README.md
README_FILEPATH="./README.md"

# Acquire a token for the Docker Hub API
echo "Acquiring token"
TOKEN="$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'$DEMYX_USERNAME'", "password": "'$DEMYX_PASSWORD'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)"

# Send a PATCH request to update the description of the repository
echo "Sending PATCH request"
REPO_URL="https://hub.docker.com/v2/repositories/${DEMYX_USERNAME}/${DEMYX_REPOSITORY}/"
RESPONSE_CODE=$(curl -s --write-out %{response_code} --output /dev/null -H "Authorization: JWT ${TOKEN}" -X PATCH --data-urlencode full_description@${README_FILEPATH} ${REPO_URL})
echo "Received response code: $RESPONSE_CODE"

if [ $RESPONSE_CODE -eq 200 ]; then
  exit 0
else
  exit 1
fi
