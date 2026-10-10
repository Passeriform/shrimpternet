#!/bin/sh

usage() {
	echo "Usage: $0 [-v] -o <meta-file> <mirror-directory>"
	echo "  -v              Enable verbose logging"
	echo "  -o <meta-file>  Output meta file path"
}

while getopts "vo:" opt; do
	case ${opt} in
		v ) VERBOSE=true ;;
		o ) OUTPUT_FILE="${OPTARG}" ;;
		\?) echo "Error: Invalid option -$OPTARG" >&2; usage ;;
		: ) echo "Error: Option -$OPTARG requires an argument." >&2; usage ;;
	esac
done

shift $((OPTIND - 1))

if [ -z "$OUTPUT_FILE" ]; then
  echo "Error: Required flag -o is missing." >&2
  usage
fi

MIRROR_DIR="$1"

if [ -z "$MIRROR_DIR" ]; then
  echo "Error: Required argument url is missing." >&2
  usage
fi

find "$MIRROR_DIR" -mindepth 2 -maxdepth 2 -name index.html | while read -r file; do
	slug=$(basename "$(dirname "$file")")
	href=blogs/"$slug"/

	sed -E '/<base [^>]*>/d; s|(<head>)|\1\n    '"<base href=\"/$href\">"'|i' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

	title=$(pup 'title text{}' < "$file" 2>/dev/null)
	description=$(pup 'meta[name="description"] attr{content}' < "$file" 2>/dev/null)
	image=blogs/$(pup 'head link[rel~="icon"], head link[rel~="shortcut icon"] attr{href}' < "$file" 2>/dev/null)

	jq -n \
	--arg slug "$slug" \
	--arg title "$title" \
	--arg description "$description" \
	--arg image "$image" \
	--arg href "$href" \
	'{slug: $slug, title: $title, description: $description, image: $image, href: $href}'
done | jq --null-input --rawfile orig "$OUTPUT_FILE" '
	($orig | fromjson | .blogs // []) + [inputs]
	| { blogs: (INDEX(.[]; .slug) | [ .[] ]) }
' > "$OUTPUT_FILE.tmp" && mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"