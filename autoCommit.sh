#!/bin/bash

# Set the directory path
directory="/home/xypnox/notes/"

# Change to the specified directory
cd $directory

# Define the branch name based on the current date
branch=$(date +%F)
date_human=$(date +"%H:%M:%S %d %b %F")

# Check if the branch already exists
branch_exists=$(git show-ref refs/heads/${branch})
num_changes=$(git status --porcelain=v1 2>/dev/null | wc -l)

# Function to check if a branch is merged into another branch
git_is_merged() {
  merge_destination_branch=$1
  merge_source_branch=$2

  merge_base=$(git merge-base $merge_destination_branch $merge_source_branch)
  merge_source_current_commit=$(git rev-parse $merge_source_branch)
  if [[ $merge_base = $merge_source_current_commit ]]
  then
    echo "$merge_source_branch is merged into $merge_destination_branch"
    return 0
  else
    echo "$merge_source_branch is not merged into $merge_destination_branch"
    return 1
  fi
}

# Function to create a commit and push changes
create_commit() {
  local gstatus=$(git status --porcelain)

  if [ ${#gstatus} -ne 0 ]
  then
    echo "Committing and pushing changes!"
    git add --all
    if [[ -n "$1" ]]
    then
      git commit -m "$1" -m "Porcelain: $gstatus"
    else
      git commit -m "$dateAuto Commit" -m "Porcelain: $gstatus"
    fi
  fi
}

# Function to checkout a branch, create a commit, and push changes
commit_and_push() {
  git checkout $1
  create_commit
  git push origin $1
}

# Function to checkout a branch, create a commit, push changes, and set tracking
commit_and_push_set_tracking() {
  git checkout $1
  create_commit
  git push -u origin $1
}

# Function to create a squash commit, push changes, and merge into main branch
create_squash_commit_push() {
  git checkout main
  local gcherry=$(git cherry -v main $1)
  git merge --squash $1
  create_commit $date_human
  git push origin main
}

# Function to check the previous day's branch, merge if necessary, and delete
prev_check() {
  local prev_branch=$(date -d "yesterday" +%F)
  local prev_branch_exists=$(git show-ref refs/heads/${prev_branch})

  if [ -n "$prev_branch_exists" ]
  then
    echo "Previous branch not deleted, processing!"

    git_is_merged main $prev_branch
    is_merged=$?
    echo $is_merged

    if [ $is_merged -eq 0 ]
    then
      echo "$prev_branch merged"
    else
      echo "$prev_branch not merged"
      commit_and_push $prev_branch
      create_squash_commit_push $prev_branch
    fi

    # Delete the previous day's branch
    git checkout main
    git branch -D $prev_branch
    git push --delete origin $prev_branch

  else
    echo "Previous branch doesn't exist, skipping"
  fi

}

# Main function
main() {
  echo -e "\n\n===Running Script===\n :at $0 \n :on $(date) \n :with $num_changes changes \n"
  prev_check

  if [ -n "$branch_exists
