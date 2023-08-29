#!/usr/bin/env bash

function write_out() {
    sed -rn -e '/^={20}[[:space:]]*'"$1"'/,/={20}/p' $0 |
    sed -r -e 1d -e '$d' \
        >$1
}

if [ ! -d .git ]; then
  echo "This script must be run from the root of a role repository" >&2
  exit 1
fi

repo_url=$(git remote get-url --push origin)
if ! echo "$repo_url" | grep "ansible-role-" &>/dev/null; then
  echo "This script must be run from the root of a role repository" >&2
  exit 1
fi

# Fix the repo URL if we are on an old clone
if echo "$repo_url" | grep -E "hpc-unibe-ch|idsys-unibe-ch" &>/dev/null; then
  git remote set-url origin "$(git remote get-url --push origin | sed -E "s#(hpc|idsys)-unibe-ch#id-unibe-ch#")"
fi

if ! gh repo view >/dev/null 2>&1; then
  echo "This repo has not been tranferred to id-unibe-ch yet. Do this in the browser first!" >&2
  exit 1
fi

git-id-branding
git fetch --all --prune || exit 1
git pull --ff-only || exit 1
git push -u origin main || exit 1

if ! gh issue list | grep "Fix meta info" &>/dev/null; then
  write_out issue_body.txt
  gh issue create \
    --title "Fix meta information after transfer to new org" \
    --label "enhancement" \
    --assignee "@me" \
    --project "Generic Ansible Roles" \
    --body-file issue_body.txt
  rm -f issue_body.txt
fi
issue_id=$(gh issue list | awk '/Fix meta info/{print $1}')

# Create feature branch
gh issue develop $issue_id
git co "$issue_id-fix-meta-information-after-transfer-to-new-org" || exit 1

# Set license and namespace
sed -i.bak "s/license:.*/license: MIT/" meta/main.yml
sed -i.bak "s/namespace:.*/namespace: unibeid/" meta/main.yml
rm meta/main.yml.bak
git add meta/main.yml
# Create license file
write_out LICENSE
git add LICENSE

# Fix namespace in project files
find [^.]* -type f |
while read -r foo; do
  if grep -E "ubelix|unibe_idsys" "$foo" >/dev/null 2>&1; then
    sed -i.bak -e 's/ubelix\./unibeid./g' -e 's/unibe_idsys\./unibeid./g' "$foo";
    git add "$foo"
    rm -f "$foo.bak"
  fi
done

git commit -m "fix: update meta information and add license" -m "Fixes #${issue_id}" || exit 1
git push || exit 1
gh pr create \
  --fill \
  --reviewer grvlbit \
  --assignee "@me" \
  --label enhancement || exit 1

exit 0

# shellcheck disable=all
{
==================== issue_body.txt ====================
As this role is being transferred to the new organization id-unibe-ch, the following changes are needed:

- set role's namespace to `unibeid` as previously defined
- set license to MIT
- add license file to the repo
==================== LICENSE ====================
MIT License

Copyright (c) 2023 IT Services Office, University of Bern

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
====================
}
