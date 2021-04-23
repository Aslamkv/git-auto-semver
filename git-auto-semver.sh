#!/bin/bash

path=$1

[ -z $path ] && path=`pwd`
[ ! -d $path ] && echo "Invalid path!" && exit 1

cd $path

[ ! -d .git ] && echo "Not inside a git repository!" && exit 1

current_version=$(git describe --abbrev=0 --tags 2>/dev/null)
current_version_commit=$(git rev-list -n 1 $current_version 2>/dev/null)
while [ -z $current_version_commit ]
do
  current_version=$(git describe --abbrev=0 --tags $current_version^ 2>/dev/null)
  if [ -z $current_version ]; then
    break
  fi
  current_version_commit=$(git rev-list -n 1 $current_version 2>/dev/null)
done

latest_commit=$(git log --format="%H" -n 1)
[[ "$latest_commit" = "$current_version_commit" ]] && echo "No changes made to release!" && exit 1

current_version=$(echo $current_version | sed 's/[^0-9\.]//g')
current_version_bits=(${current_version//./ })

major=${current_version_bits[0]}
minor=${current_version_bits[1]}
patch=${current_version_bits[2]}

[ -z $major ] && major=0
[ -z $minor ] && minor=0
[ -z $patch ] && patch=0

latest_commit_message=$(git log --pretty="%s" master -1 --no-merges)
mode='minor'

[[ $latest_commit_message =~ 'Fix' ]] && mode='patch'
[[ $latest_commit_message =~ 'Release' ]] && mode='major'

case "$mode" in
    "major") major=$((major+1)) && minor=0 && patch=0 ;;
    "minor") minor=$((minor+1)) && patch=0 ;;
    "patch") patch=$((patch+1)) ;;
esac
new_version='v'$major'.'$minor'.'$patch

new_version_commit=$(git rev-list -n 1 $new_version 2>/dev/null)

[[ "$current_version_commit" = "$new_version_commit" ]] && echo "v$current_version already released!" && exit 1

git tag -d $(git tag -l)
git pull --tags
git tag -a $new_version -m "$latest_commit_message"
echo -e '\E[47;31m'"\033[1mReleasing version $new_version\033[0m"
git push --tags
