#!/bin/bash

path=$1

[ -z $path ] && path=`pwd`
[ ! -d $path ] && echo "Invalid path!" && exit 1

cd $path

[ ! -d .git ] && echo "Not inside a git repository!" && exit 1

major=0
minor=0
patch=0

git pull --tags

IFS=$'\n'
for commit_message in $(git log --pretty="%s" --no-merges --reverse);
do
  mode='minor'
  [[ $commit_message =~ 'Fixed' ]] && mode='patch'
  [[ $commit_message =~ 'Released' ]] && mode='major'

  case "$mode" in
      "major") major=$((major+1)) && minor=0 && patch=0 ;;
      "minor") minor=$((minor+1)) && patch=0 ;;
      "patch") patch=$((patch+1)) ;;
  esac
  version='v'$major'.'$minor'.'$patch
  version_commit=$(git rev-list -n 1 $version 2>/dev/null)
  [[ ! -z $version_commit ]] && git tag -a $version -m "$commit_message"
done

git push --tags
