#!/usr/bin/env bash

declare -a roles

role_prefix=ansible-role-
org=id-unibe-ch

function __update_repo {
  local gh_repo; gh_repo="$1"
  local local_repo_path; local_repo_path=$(__get_clone_dir "$gh_repo")

  if [ ! -d "$local_repo_path" ]; then
    gh repo clone "$gh_repo"  "$local_repo_path"
    __fqcn_link "$gh_repo"
  fi

  git -C "$local_repo_path" fetch --all --prune
}

function __fqcn_link {
  local gh_repo; gh_repo="$1"
  local local_repo_path; local_repo_path=$(__get_clone_dir "$gh_repo")

  if [ ! -d "$local_repo_path" ]; then
    return 1
  fi

  namespace=$(awk '/namespace:/{print $2}' "$local_repo_path/meta/main.yml")
  role_name=$(basename "$local_repo_path")
  linkt_target="roles/$namespace.$role_name"

  if [ ! -h "$linkt_target" ]; then
    ln -s "$role_name" "$linkt_target"
  fi
}

function __get_bare_role_of_orgrepo {
  echo "${1##*"$role_prefix"}"
}

function __get_role_name_orgrepo {
  echo "${1##*/}"
}

function __get_clone_dir {
  echo "roles/$(__get_bare_role_of_orgrepo "$1")"
}


# shellcheck disable=SC2207
# Fetch all roles that match the role_pattern and are not forks or archived
roles=(
  $(gh repo list "$org" \
  --json name,isFork,isArchived \
  --jq '.[] | select((.name | startswith("'$role_prefix'")) and (.isFork == false) and (.isArchived == false)) | .name')
)

for role in "${roles[@]}"; do
  printf -- "-- Working on %s\n" "$role"
  __update_repo "$role"
  ./set_repository_settings.sh $role
  printf -- "-- Done with %s\n\n" "$role"
done
