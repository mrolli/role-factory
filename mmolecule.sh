#!/bin/bash

# function wrapper to issue molecule commands for multiple distros
mmolecule() {
    local distros
    local default_distros="rockylinux8,rockylinux9,ubuntu2004,ubuntu2204"
    local default_distros; default_distros=$(awk 'match($0, /distro: \[.*\]/) {print substr($0, RSTART+9, RLENGTH-10)}' .github/workflows/ci.yml)

    if [ -z "$1" ]; then
        echo "Usage: mmolecule <distros> <commands/options>"
        return 1
    fi

    distros="$1"
    shift

    if [ "$distros" = "all" ]; then
      distros=$default_distros
    fi

    IFS=',' read -rA DISTROS <<< "$distros"
    for dist in "${DISTROS[@]}"; do
      dist=$(echo "$dist" | tr -d '[:space:]')
      echo MOLECULE_DISTRO="$dist" molecule "$@"
    done
}
