#!/usr/bin/env bash

declare -a repos
declare -a orgs

role_pattern=ansible-role-
orgs=(
  idsys-unibe-ch
  hpc-unibe-ch
)

function __clone {
  local gh_repo; gh_repo=$1
  local target_repo; target_repo=$(__get_clone_dir_for_repo "$gh_repo")

  if [ ! -d "$target_repo" ]; then
    gh repo clone "$gh_repo"  "$target_repo"
  fi
}

function __update {
  git -C "$(__get_clone_dir_for_repo "$1")" fetch --all --prune
}

function __fqcn_link {
  local target_repo; target_repo=$(__get_clone_dir_for_repo "$1")

  if [ ! -d "$target_repo" ]; then
    return 1
  fi

  namespace=$(awk '/namespace:/{print $2}' "$target_repo/meta/main.yml")
  role_name=$(basename "$target_repo")
  linkt_target="roles/$namespace.$role_name"

  if [ ! -h "$linkt_target" ]; then
    ln -s "$role_name" "$linkt_target"
  fi
}

function __get_clone_dir_for_repo {
  echo "roles/${1##*-}"
}

for org in "${orgs[@]}"; do
  repos+=("$(gh repo list "$org" | awk '/'$role_pattern'/{print $1}')")
done

for repo in "${repos[@]}"; do
  printf -- "-- Working on %s\n" "$repo"
  __clone "$repo"
  __update "$repo"
  __fqcn_link "$repo"
  printf -- "-- Done with %s\n\n" "$repo"
done
