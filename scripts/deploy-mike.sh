#!/usr/bin/env bash

# configure git to make mike work
git config user.name "${BUILD_SOURCEVERSIONAUTHOR:-'Mauwii'}"
git config user.email "${BUILD_REQUESTEDFOREMAIL:-'mauwii@mauwii.onmicrosoft.com'}"

# delete local gh-pages branch
git branch -D gh-pages

# set branchname for mike deployment
[[ $ISPULLREQUEST == "True" ]] \
  && branchname="${SYSTEM_PULLREQUEST_SOURCEBRANCH}" \
  || branchname="${BUILD_SOURCEBRANCH#refs/heads/}"

# set versionname for mike deployment
versionName=${branchname//\//-}

# find currently deployed version for this branch
deleteVersion="$(mike list -j | jq '.[] | .version' | grep -m 1 ${versionName})"

# delete the currently deployed version
[[ -n "${deleteVersion}" ]] \
  && mike delete "${deleteVersion}" \
  || echo "no Version deployed yet for ${versionName}"

# if not pull request, deploy version
if [[ $ISPULLREQUEST != "True" ]]; then
  echo "deploying version ${versionName}.$BUILD_BUILDID to gh-pages"
  mike deploy \
    --title "${versionName}" \
    --update-aliases "${versionName}.$BUILD_BUILDID" "${versionName}"
fi

# push to gh-pages
git push origin gh-pages
