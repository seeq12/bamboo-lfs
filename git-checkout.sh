#!/usr/bin/env bash

set -ex

REPO=$bamboo_planRepository_repositoryUrl
WORKDIR=$bamboo_build_working_directory
BRANCH=$bamboo_planRepository_branch
COMMIT=$bamboo_planRepository_revision
WORKTREEOF=

while [[ $# > 0 ]]
do
  case $1 in
      --repo)
      REPO="$2"
      shift
      ;;
      --workdir)
      WORKDIR="$2"
      shift
      ;;
      --branch)
      BRANCH="$2"
      shift
      ;;
      --commit)
      COMMIT="$2"
      shift
      ;;
      --worktreeof)
      WORKTREEOF="$2"
      shift
      ;;
      *)
      UnrecognizedParameter $1
      ;;
  esac
  shift # past argument or value
done

if [ "$REPO" = "" ]; then
  if [ "$WORKTREEOF" = "" ]; then
    echo 'Please specify a repo using $bamboo_planRepository_repositoryUrl or supply a --worktreeof argument!'
    exit 1
  fi
fi
if [ "$WORKDIR" = "" ]; then
  echo 'Please specify a working directory using $bamboo_build_working_directory !'
  exit 1
fi
if [ "$BRANCH" = "" ]; then
  echo 'Please specify a branch using $bamboo_planRepository_branch !'
  exit 1
fi
if [ "$COMMIT" = "" ]; then
  echo 'Please specify a commit using $bamboo_planRepository_revision !'
  exit 1
fi

echo "Repo: $REPO"
echo "Working directory: $WORKDIR"
echo "Branch: $BRANCH"
echo "Commit: $COMMIT"
echo "Worktree Of: $WORKTREEOF"

if [ ! "$WORKTREEOF" = "" ]; then
  cd $WORKTREEOF
  git fetch --prune
  if [ ! -e "$WORKDIR/.git" ]; then
    echo 'Creating worktree...'
    git worktree prune
    git worktree add -f --no-checkout $WORKDIR origin/$BRANCH
  fi
  cd $WORKDIR
elif [ ! -d "$WORKDIR" ]; then
  echo 'Cloning clean repo to working directory...'
  git clone -b origin/$BRANCH --single-branch $REPO $WORKDIR
  cd $WORKDIR
else
  cd $WORKDIR
  if [ ! -d ".git" ]; then
    echo 'Working directory clean, cloning clean repo...'
    git clone -b origin/$BRANCH --single-branch $REPO .
  else
    repo=$(git config --get remote.origin.url)

    if [ "$repo" != "$REPO" ]; then
      echo "Existing repo $repo does not match specified repo $REPO\; aborting"
      exit 10
    fi

    echo 'Updating existing repo...'
    git fetch --prune
  fi
fi

git checkout -f -B origin/$BRANCH $COMMIT
