#!/bin/sh

VERBOSE=false
OUTPUT_DIR=""
QUALITY=720p

usage() {
  echo "Usage: $0 [-v] [-q quality] -o <directory> <playlist-id>"
  echo "  -v              Enable verbose logging"
  echo "  -q              Video quality"
  echo "  -o <directory>  Output directory"
}

while getopts "vo:q:" opt; do
  case ${opt} in
    v ) VERBOSE=true ;;
    o ) OUTPUT_DIR="${OPTARG}" ;;
    q ) QUALITY="${OPTARG}" ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; die usage ;;
    : ) echo "Error: Option -$OPTARG requires an argument." >&2; die usage ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$OUTPUT_DIR" ]; then
  echo "Error: Required flag -o is missing." >&2
  die usage
fi

PLAYLIST_ID="$1"

if [ -z "$PLAYLIST_ID" ]; then
  echo "Error: Required argument playlist id is missing." >&2
  die usage
fi

LOCKFILE="${OUTPUT_DIR}/yt.lock"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/yt-playlist.XXXXXX")" || die "can't create temp dir"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT
trap 'exit 130' INT TERM

[[ "$QUALITY" =~ ^([0-9]+)p?$ ]] || die "-q must look like 720p (got '$QUALITY')."
HEIGHT="${BASH_REMATCH[1]}"

FORMAT="bv*+ba/b"
(( HEIGHT > 0 )) && FORMAT="bv*[height<=${HEIGHT}]+ba/b[height<=${HEIGHT}]"

yt-dlp \
  --yes-playlist \
  --no-overwrites \
  --continue \
  --download-archive "$LOCKFILE" \
  --retries 10 \
  --fragment-retries 10 \
  --no-write-playlist-metafiles \
  --paths "home:$OUTPUT_DIR" \
  --paths "temp:$WORKDIR" \
  --paths "thumbnail:$WORKDIR" \
  --output "%(title)s.%(ext)s" \
  --format "$FORMAT" \
  --merge-output-format mp4 \
  --embed-thumbnail \
  --embed-metadata \
  --parse-metadata "%(playlist_title)s:%(meta_playlist)s" \
  --parse-metadata "%(duration)s:%(meta_length)s" \
  --parse-metadata "0:%(meta_plays)s" \
  --postprocessor-args "Metadata:-movflags use_metadata_tags" \
  "https://www.youtube.com/playlist?list=$PLAYLIST_ID"
