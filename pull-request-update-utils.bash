#!/bin/bash

set -euo pipefail

function gh_api
{
    gh api \
       -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       "$@"
}

function pull_requests_with_base
{
    base="$1"

    gh pr list \
       --base "$base" \
       --json number \
       --jq ".[] | .number"
}

function rebase_onto
{
    base="$1"
    name=$(git show -s --format='%cn')
    email=$(git show -s --format='%ce')

    git \
      -c user.name="$name" \
      -c user.email="$email" \
      -c advice.mergeConflict=false \
      rebase --onto "$base" HEAD~1
}

function try_update_with
{
    pr="$1"
    base="$2"

    gh pr checkout "$pr" >/dev/null 2>&1

    if rebase_onto "$base"; then
        git push origin --force-with-lease --quiet
        gh pr edit --base "${base#*/}" >/dev/null
        echo "...✅"
    else
        echo "...failed to rebase ❌"
        git rebase --abort
    fi
}
