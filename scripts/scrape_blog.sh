#!/bin/sh

VERBOSE=false
OUTPUT_DIR=""

usage() {
  echo "Usage: $0 [-v] -o <directory> <url>"
  echo "  -v              Enable verbose logging"
  echo "  -o <directory>  Output directory"
}

while getopts "vo:" opt; do
  case ${opt} in
    v ) VERBOSE=true ;;
    o ) OUTPUT_DIR="${OPTARG}" ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; usage ;;
    : ) echo "Error: Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$OUTPUT_DIR" ]; then
  echo "Error: Required flag -o is missing." >&2
  usage
fi

TARGET_URL="$1"

if [ -z "$TARGET_URL" ]; then
  echo "Error: Required argument url is missing." >&2
  usage
fi

wget2 \
  `# Mode` --mirror \
  `# Behavior` --page-requisites --adjust-extension --convert-links --no-parent \
  `# Performance` --http2 --max-threads=5 --compression=gzip,br,zstd \
  `# Identity` --user-agent="Shrimpternet/visitor" \
  `# Kindness` --wait=2 --random-wait --limit-rate=200k \
  `# Local` --directory-prefix="$OUTPUT_DIR" \
  `# Website` "$TARGET_URL"

# Fix inferred relative URLs
find "$OUTPUT_DIR" -name "*.html" -exec sed -i -E 's/(href|src)="([a-zA-Z0-9][^:"]*)"/\1=".\/\2"/g' {} +
