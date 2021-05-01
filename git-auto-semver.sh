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

git_tag_count=$(git tag | wc -l)
git_commit_count=$(git log --pretty="%s" --no-merges --reverse | wc -l)

if [[ $git_tag_count > $git_commit_count ]]; then
  git push origin --delete $(git tag -l)
  git tag -d $(git tag -l)
fi

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
  if [[ -z $version_commit ]]; then
    echo "Commit:$commit_message version:$version"
    git tag -a $version -m "$commit_message"
  fi
done

git push --tags
