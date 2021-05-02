#!/bin/bash
PURPLE='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m'

show_version_commit(){
  local commit_message=$1
  local version=$2
  echo -e "Commit:${PURPLE}$commit_message${NC} version:${RED}$version${NC}"
}

get_commits(){
  git log --pretty="%s" --no-merges --reverse
}

get_mode(){
  local commit_message=$1
  local mode='minor'
  [[ $commit_message =~ 'Fixed' ]] && mode='patch'
  [[ $commit_message =~ 'Released' ]] && mode='major'
  echo $mode
}

run(){
  local major=0
  local minor=0
  local patch=0

  git pull --tags

  local git_tag_count=$(git tag | wc -l)
  local git_commit_count=$(get_commits | wc -l)

  if [[ $git_tag_count > $git_commit_count ]]; then
    git push origin --delete $(git tag -l)
    git tag -d $(git tag -l)
  fi

  IFS=$'\n'
  for commit_message in $(get_commits);
  do
    local mode=$(get_mode $commit_message)

    case "$mode" in
        "major") major=$((major+1)) && minor=0 && patch=0 ;;
        "minor") minor=$((minor+1)) && patch=0 ;;
        "patch") patch=$((patch+1)) ;;
    esac

    local version='v'$major'.'$minor'.'$patch
    local version_commit=$(git rev-list -n 1 $version 2>/dev/null)
    if [[ -z $version_commit ]]; then
      show_version_commit $commit_message $version
      git tag -a $version -m "$commit_message"
      git push origin $version
    fi
  done
}

list(){
  local major=0
  local minor=0
  local patch=0

  IFS=$'\n'
  for commit_message in $(get_commits);
  do
    local mode=$(get_mode $commit_message)

    case "$mode" in
        "major") major=$((major+1)) && minor=0 && patch=0 ;;
        "minor") minor=$((minor+1)) && patch=0 ;;
        "patch") patch=$((patch+1)) ;;
    esac
    local version='v'$major'.'$minor'.'$patch
    show_version_commit $commit_message $version
  done
}

check_path(){
  local path=$1
  [ ! -d $path ] && echo "Invalid path!" && exit 1
  cd $path
  local inside_git_repo=$(git rev-parse --is-inside-work-tree 2>/dev/null)
  [ -z $inside_git_repo ] && echo "Not inside a git repository!" && exit 1
}

show_help(){
  echo -e "Utility to list or update git tags using git logs with semantic versioning.\n"
  echo "Usage: $0 [-l|--list] [-p|--path]"
  echo -e "\nArguments\n"
  echo -e "\t-l, --list \t\tLists all version commits. Used to list tags before updating them.\n"
  echo -e "\t-p, --path <PATH> \tPath to the git repository.\n"
  exit 0
}

path=`pwd`
only_list_commit_versions=false

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -h|--help)
        show_help
        ;;
      -p|--path)
        path="$2"
        shift
        shift
        ;;
      -l|--list)
        only_list_commit_versions=true
        shift
        shift
        ;;
      *)
        shift
        ;;
  esac
done

check_path $path

if $only_list_commit_versions; then
  list
else
  run
fi
