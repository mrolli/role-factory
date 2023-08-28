#!/usr/bin/env bash

# The URL must contain <num> for the reference number.
snow_query_url="https://serviceportal.unibe.ch/text_search_exact_match.do?sysparm_search=<num>"

# Set who we are and where we are
script=$(basename "${0}")
# script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit 1 ; pwd -P )"

# Output stylinge variables
if tput setaf 1 &> /dev/null
then
  # shellcheck disable=SC2034
  {
  reset=$(tput sgr0)
  bold=$(tput bold)
  underline=$(tput smul)
  nounderline=$(tput rmul)
  fg=$(tput setaf 223)
  aqua=$(tput setaf 72)
  black=$(tput setaf 0)
  blue=$(tput setaf 4)
  green=$(tput setaf 2)
  orange=$(tput setaf 166)
  purple=$(tput setaf 5)
  red=$(tput setaf 1)
  white=$(tput setaf 15)
  yellow=$(tput setaf 11)
  }
fi

function __prompt_confirm {
  while true; do
    printf "\r[ %s ] %s [y/n]: " "${yellow}??${reset}" "${*:-Confirm?}"
    read -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " ${yellow}%s${reset}\n" "invalid input"
    esac
  done
}

function info {
  [ "${quiet:-0}" -lt 1 ] && printf "[ ${blue}..${reset} ] %s: %s\n" "$script" "${*}"
}

function debug {
  [ "${debug:-0}" -eq 1 ] && printf "[${yellow}DEBG${reset}] %s: %s\n" "$(basename "$0")" "${*}"
}

function warning {
  [ "${quiet:-0}" -lt 1 ] && printf "[ ${yellow}!!${reset} ] %s: %s\n" "$(basename "$0")" "${*}" >&2
}

# Print given string with a fail decoration
function success {
  [ "${quiet:-0}" -lt 1 ] && printf "[ ${green}OK${reset} ] %s: %s\n" "$(basename "$0")" "${*}"
}

# Use this print funciton for failures
function fail {
  [ "${quiet:-0}" -lt 2 ] && printf "[${red}FAIL${reset}] %s: %s\n" "$(basename "$0")" "${*}" >&2
}

# Check if a command is found in $PATH
function __assert_command_exists {
  local cmd="${1}"

  debug "Looking for command -- ${cmd}"

  if ! fcmd=$(command -v "$1")
  then
    fail "Command not found -- ${cmd}"
    exit 1
  fi

  debug "  - found ${fcmd}"
  return 0
}

function __assert_is_logged_in_GH {
  if ! authout=$(gh auth status 2>&1); then
    fail "You are not logged in with gh. Configure gh first"
    exit 1
  else
    debug "$authout"
  fi
  return 0
}

function print_usage {
  echo -n >&2 "Usage:
  ${script} [-h] [-d] [-q|-qq] ${underline}OWNER/REPO${nounderline}

Command line arguemnts:
  -d     Output debug information
  -h     Print usage information
  -f/-y  Assume yes to all questions and run non-interactively
  -q     suppress non-error messages
  -qq    suppress all messages
"
}

function setup_snow_autolinkref {
  autolinkref=$(gh api --method GET \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$repo/autolinks" --jq '.[] | select(.key_prefix=="SNOW-")'
  )

  debug "SNOW autlink reference found: $autolinkref"

  if [ -n "$autolinkref" ]; then
    success "Autolink reference for SNOW already setup."
    return 0
  fi

  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$repo/autolinks" \
    -f key_prefix="SNOW-" \
   -f url_template="$snow_query_url" \
   -F is_alphanumeric=true
}

function protect_main_branch {
  gh api \
    --method PUT "/repos/$repo/branches/main/protection" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Accept: application/vnd.github+json" \
    -F 'required_pull_request_reviews[dismiss_stale_review]=true' \
    -F 'required_pull_request_reviews[require_code_owner_reviews]=true' \
    -F 'required_pull_request_reviews[required_approving_review_count]=1' \
    -F 'required_pull_request_reviews[require_last_push_approval]=true' \
    -F 'required_linear_history=false' \
    -F 'required_status_checks=null' \
    -F 'restrictions=null' \
    -F 'enforce_admins=true'
}
### Main script starts here

# Define global variables and their defaults
debug=0
quiet=0
force=0
repo=""

# arguments and options partion
while getopts :dfhqy OPTION
do
  case "${OPTION}" in
    h)
      print_usage
      exit 0
      ;;
    d)
      debug=1
      ;;
    q)
      quiet=$((quiet+=1))
      ;;
    f|y)
      force=1
      ;;
    :)
      warning "${script}: option ${OPTARG} requires an argument"
      print_usage
      exit 1
      ;;
    ?)
      warning "${script}: illegal option ${OPTARG}"
      print_usage
      exit 1
      ;;
  esac
done

repo=${*:$((OPTIND)):1}
[ -z "$repo" ] && fail "missing the group name" \
               && print_usage \
               && exit 1

__assert_command_exists git
__assert_command_exists gh
__assert_is_logged_in_GH

gh_host=${GH_HOST:-github.com}
gh_user=$(gh auth status 2>&1 | awk '/Logged in to '"$gh_host"'/{print $7}')


debug "Arguments and options parsing results:"
debug "  - quiet = $quiet"
debug "  - debug = $debug"
debug "  - repo = $repo"
debug "  - gh_host = $gh_host"
debug "  - gh_user = $gh_user"

if ! gh repo view "$repo" >/dev/null 2>&1; then
  fail "Repository not found"
  exit 2
fi

# gh api \
#   -H "Accept: application/vnd.github+json" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   "/repos/$repo/collaborators/mrolli/permission" >/dev/null

if [ $force -eq 1 ] ||
      __prompt_confirm "Do you want to setup autolink reference to Service Now in this repo?"; then
  setup_snow_autolinkref
else
  debug "Skipping autolink reference setup"
fi

if [ $force -eq 1 ] ||
      __prompt_confirm "Do you want to protect the main branch?"; then
  protect_main_branch
else
  debug "Skipping main branch protection setup"
fi

exit
