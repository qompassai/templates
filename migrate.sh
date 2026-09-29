#!/usr/bin/env bash
set -Eeuo pipefail

DEST_ROOT="/home/phaedrus/.GH/Qompass/Templates"
TEMPLATES_REPO="$DEST_ROOT"
GITIGNORE_PATH="$TEMPLATES_REPO/.gitignore"
GITHUB_OWNER="qompassai"
DEFAULT_BRANCH="main"

REPOS=(
    angle-template
    ansible-template
    azure-template
    c--template
    c-template
    containers-template
    cpp-template
    css-template
    cuda-template
    deno-template
    dns-template
    dotnet-template
    git-template
    gnupg-template
    gtk-template
    haskell-template
    html-template
    hyprland-template
    java-template
    js-template
    json-template
    k8s-template
    latex-template
    mariadb-template
    maven-template
    mesa-template
    mysql-template
    neomutt-template
    network-template
    nginx-template
    nix-template
    obs-template
    pam-template
    php-template
    pipewire-template
    psql-template
    salesforce-template
    scala-template
    shell-template
    sqlite-template
    svg-template
    tauri-template
    terraform-template
    tor-template
    typescript-template
    unreal-template
    valkey-template
    vite-template
    volta-template
    vulkan-template
    wasm-template
    wayland-template
    yaml-template
    zig-template
)

log()
{
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_cmd()
{
    command -v "$1" > /dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

ensure_git_repo()
{
    if [[ ! -d "$TEMPLATES_REPO/.git" ]]; then
        printf 'Expected a git repository at %s\n' "$TEMPLATES_REPO" >&2
        printf 'Initialize it first or change TEMPLATES_REPO in this script.\n' >&2
        exit 1
    fi
}

append_gitignore_once()
{
    local entry="$1"
    touch "$GITIGNORE_PATH"
    if ! grep -Fxq "$entry" "$GITIGNORE_PATH"; then
        printf '%s\n' "$entry" >> "$GITIGNORE_PATH"
        log "Added to .gitignore: $entry"
    fi
}

clone_or_update()
{
    local repo="$1"
    local url="https://github.com/${GITHUB_OWNER}/${repo}.git"
    local target="$DEST_ROOT/$repo"

    if [[ -d "$target/.git" ]]; then
        log "Updating $repo"
        git -C "$target" remote set-url origin "$url"
        git -C "$target" fetch --prune origin
        if git -C "$target" show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
            git -C "$target" checkout "$DEFAULT_BRANCH" > /dev/null 2>&1 || true
            git -C "$target" pull --ff-only origin "$DEFAULT_BRANCH"
        else
            log "Skipping pull for $repo: origin/$DEFAULT_BRANCH not found"
        fi
    elif [[ -e $target ]]; then
        log "Skipping $repo: target exists but is not a git repo -> $target"
    else
        log "Cloning $repo"
        git clone "$url" "$target"
    fi

    append_gitignore_once "/$repo/"
}

main()
{
    require_cmd git
    mkdir -p "$DEST_ROOT"
    ensure_git_repo

    for repo in "${REPOS[@]}"; do
        clone_or_update "$repo"
    done

    log "Done. Repositories synced into $DEST_ROOT"
    log "Review changes with: git -C '$TEMPLATES_REPO' status"
}

main "$@"
