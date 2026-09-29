#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/home/phaedrus/.GH/Qompass/Templates"
TARGET_REL=".github/workflows"
DRY_RUN=false
COMMIT_MESSAGE="chore: remove GitHub Actions workflows"
PUSH_REMOTE="origin"
PUSH_BRANCH=""

usage()
{
    cat << 'EOF'
Usage: remove-template-workflows.sh [--dry-run] [--message "msg"] [root_dir]

Removes .github/workflows from each immediate child repository under the root,
then commits and pushes the change in each affected repository.
Run this from /home/phaedrus/.GH/Qompass/Templates or pass a custom root path.

Options:
  --dry-run          Show what would be removed, committed, and pushed.
  --message "msg"   Commit message to use.
  -h, --help         Show this help.
EOF
}

log()
{
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

parse_args()
{
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --message)
                [[ $# -ge 2 ]] || {
                    printf '--message requires a value\n' >&2
                    exit 1
                }
                COMMIT_MESSAGE="$2"
                shift 2
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                ROOT_DIR="$1"
                shift
                ;;
        esac
    done
}

current_branch()
{
    git -C "$1" symbolic-ref --quiet --short HEAD 2> /dev/null || true
}

push_branch_for_repo()
{
    local repo_dir="$1"
    local branch
    branch="$(current_branch "$repo_dir")"
    if [[ -n $PUSH_BRANCH ]]; then
        printf '%s\n' "$PUSH_BRANCH"
    elif [[ -n $branch ]]; then
        printf '%s\n' "$branch"
    else
        printf 'main\n'
    fi
}

remove_commit_push_one()
{
    local repo_dir="$1"
    local target="$repo_dir/$TARGET_REL"
    local branch

    [[ -d $target ]] || return 0
    branch="$(push_branch_for_repo "$repo_dir")"

    if [[ $DRY_RUN == true ]]; then
        log "Would remove: $target"
        log "Would commit in $(basename "$repo_dir"): $COMMIT_MESSAGE"
        log "Would push $(basename "$repo_dir") -> $PUSH_REMOTE/$branch"
        return 0
    fi

    rm -rf -- "$target"
    log "Removed: $target"

    git -C "$repo_dir" add -A -- "$TARGET_REL"

    if git -C "$repo_dir" diff --cached --quiet; then
        log "No staged changes after removal in $(basename "$repo_dir"), skipping commit/push"
        return 0
    fi

    git -C "$repo_dir" commit -m "$COMMIT_MESSAGE"

    if git -C "$repo_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' > /dev/null 2>&1; then
        git -C "$repo_dir" push
    else
        git -C "$repo_dir" push --set-upstream "$PUSH_REMOTE" "$branch"
    fi

    log "Pushed $(basename "$repo_dir") -> $PUSH_REMOTE/$branch"
}

main()
{
    parse_args "$@"

    if [[ ! -d $ROOT_DIR ]]; then
        printf 'Root directory does not exist: %s\n' "$ROOT_DIR" >&2
        exit 1
    fi

    if [[ $PWD != "$ROOT_DIR" ]]; then
        log "Working from $PWD, targeting $ROOT_DIR"
    fi

    local repo_dir
    shopt -s nullglob
    for repo_dir in "$ROOT_DIR"/*; do
        [[ -d $repo_dir ]] || continue
        [[ -d "$repo_dir/.git" ]] || continue
        remove_commit_push_one "$repo_dir"
    done
    shopt -u nullglob

    log "Done"
}

main "$@"
