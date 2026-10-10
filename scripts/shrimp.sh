#!/bin/sh

DEBUG_CONFIG_DIR="${SHRIMP_HOME:+${SHRIMP_HOME}/.config/shrimpternet}"
DEBUG_CACHE_DIR="${SHRIMP_HOME:+${SHRIMP_HOME}/.cache/shrimpternet}"

CONFIG_DIR="${DEBUG_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/shrimpternet}"
CACHE_DIR="${DEBUG_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/shrimpternet}"

BLOGS_CONFIG_FILE="${CONFIG_DIR}/blogs"
YOUTUBE_CONFIG_FILE="${CONFIG_DIR}/youtube"

BLOGS_CACHE_DIR="${CACHE_DIR}/blogs"
YOUTUBE_CACHE_DIR="${CACHE_DIR}/youtube"

META_FILE="${CACHE_DIR}/meta.json"

USAGE=$(cat << 'EOF'
========= Shrimpternet =========
Available commands:
    run    - Runs the Shrimpternet
    update - Crawls the Internet and updates Shrimpternet
================================
EOF
)

update() {
    xargs -I {} -P 4 -n 1 scrape_blog -o "${BLOGS_CACHE_DIR}" {} < "${BLOGS_CONFIG_FILE}" &
    xargs -I {} -P 4 -n 1 scrape_youtube -o "${YOUTUBE_CACHE_DIR}" {} < "${YOUTUBE_CONFIG_FILE}" &
    extract_meta -o "${META_FILE}" "${BLOGS_CACHE_DIR}" &
}

run() {
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    serve "${BLOGS_CACHE_DIR}" "${SCRIPT_DIR}/../share/assets" 4000
}

mkdir -p "${CONFIG_DIR}"
mkdir -p "${BLOGS_CACHE_DIR}"
mkdir -p "${YOUTUBE_CACHE_DIR}"

if [ $# -lt 1 ]; then
    fry & serve
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
    run)    run ;;
    update) update & wait ;;
    help)   echo "${USAGE}" ;;
    *)
        echo "Unknown subcommand: $SUBCOMMAND" >&2
        echo "\n${USAGE}"
        exit 1
    ;;
esac