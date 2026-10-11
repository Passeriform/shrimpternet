#!/bin/sh

SHRIMP_CONFIG_DIR="${SHRIMP_HOME:+${SHRIMP_HOME}/.config/shrimpternet}"
SHRIMP_CACHE_DIR="${SHRIMP_HOME:+${SHRIMP_HOME}/.cache/shrimpternet}"

CONFIG_DIR="${SHRIMP_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/shrimpternet}"
CACHE_DIR="${SHRIMP_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/shrimpternet}"

BLOGS_CONFIG_FILE="${CONFIG_DIR}/blogs"
YOUTUBE_CONFIG_FILE="${CONFIG_DIR}/youtube"

BLOGS_CACHE_DIR="${CACHE_DIR}/blogs"
YOUTUBE_CACHE_DIR="${CACHE_DIR}/youtube"

META_FILE="${CACHE_DIR}/meta.json"

LOG_FILE="${SHRIMP_LOG:-/dev/null}"

USAGE=$(cat << 'EOF'
========= Shrimpternet =========
Available commands:
    run    - Runs the Shrimpternet
    update - Crawls the Internet and updates Shrimpternet
================================
EOF
)

cleanup() {
    trap '' SIGINT SIGTERM
    kill 0
    wait
} 2>/dev/null

update() {
    trap cleanup SIGINT SIGTERM

    exec > "${LOG_FILE}"
    if [ "${LOG_FILE}" != "/dev/stdout" ] && [ "${LOG_FILE}" != "/dev/stderr" ] && [ "${LOG_FILE}" != "/dev/null" ]; then
        exec 2>&1
    fi

    xargs -I {} -P 4 -n 1 scrape_blog -o "${BLOGS_CACHE_DIR}" {} < "${BLOGS_CONFIG_FILE}" &
    xargs -I {} -P 4 -n 1 scrape_youtube -o "${YOUTUBE_CACHE_DIR}" {} < "${YOUTUBE_CONFIG_FILE}" &
    wait

    extract_meta -o "${META_FILE}" "${BLOGS_CACHE_DIR}"
}

run() {
    trap cleanup SIGINT SIGTERM

    exec > "${LOG_FILE}"
    if [ "${LOG_FILE}" != "/dev/stdout" ] && [ "${LOG_FILE}" != "/dev/stderr" ] && [ "${LOG_FILE}" != "/dev/null" ]; then
        exec 2>&1
    fi

    SCRIPT_DIR=$(dirname $0)
    serve "${BLOGS_CACHE_DIR}" "${SCRIPT_DIR}/../share/assets" 4000 &
    wait
}

if [ $# -lt 1 ]; then
    update && run
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
    run)    run ;;
    update) update ;;
    help)   echo "${USAGE}" ;;
    *)
        echo "Unknown subcommand: $SUBCOMMAND" >&2
        echo "\n${USAGE}"
        exit 1
    ;;
esac