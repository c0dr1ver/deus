#!/bin/bash

show_help() {
    cat << 'EOF'
Usage:
  ./deus.sh /absolute/path [--ext EXT]

Description:
  Scans a directory recursively, calculates total size of files with a given
  extension, shows their distribution by top-level folders, and prints the
  percentage relative to the total size of all files in the scanned directory.

Arguments:
  /absolute/path        Absolute path to the target folder

Options:
  --ext EXT             File extension (e.g. mp3, pdf)
  -h, --help            Show this help message

Examples:
  ./deus.sh /home/user/Downloads --ext mp3
  ./deus.sh /home/user/Downloads
EOF
}

format_time() {
    local total=$1
    local h=$((total / 3600))
    local m=$(((total % 3600) / 60))
    local s=$((total % 60))

    if (( h > 0 )); then
        printf "%dh %02dm %02ds" "$h" "$m" "$s"
    elif (( m > 0 )); then
        printf "%dm %02ds" "$m" "$s"
    else
        printf "%ds" "$s"
    fi
}

spinner() {
    local pid=$1
    local delay=0.1
    local frames='|/-\'
    local i=0

    tput civis 2>/dev/null

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\rScanning... %c" "${frames:$i:1}"
        sleep "$delay"
    done

    printf "\r%-30s\r" " "
    tput cnorm 2>/dev/null
}

START_TIME=$(date +%s)

EXT=""
BASE_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --ext)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --ext requires a value."
                exit 1
            fi
            EXT="$2"
            shift 2
            ;;
        *)
            if [[ -n "$BASE_DIR" ]]; then
                echo "Error: multiple paths are not supported."
                exit 1
            fi
            BASE_DIR="$1"
            shift
            ;;
    esac
done

if [[ -z "$BASE_DIR" ]]; then
    show_help
    exit 1
fi

if [[ "$BASE_DIR" != /* ]]; then
    echo "Error: you must specify an absolute path."
    exit 1
fi

if [[ ! -e "$BASE_DIR" ]]; then
    echo "Error: path does not exist: $BASE_DIR"
    exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: path is not a directory: $BASE_DIR"
    exit 1
fi

if [[ -z "$EXT" ]]; then
    read -rp "Enter the file extension (e.g. mp3, pdf): " EXT
fi

EXT="${EXT#.}"

if [[ -z "$EXT" ]]; then
    echo "Error: file extension is not specified."
    exit 1
fi

BASE_DIR="${BASE_DIR%/}"
EXT_LC=$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')

TMPFILE=$(mktemp) || {
    echo "Error: failed to create temporary file."
    exit 1
}

cleanup() {
    rm -f "$TMPFILE"
    tput cnorm 2>/dev/null
}
trap cleanup EXIT

(
find "$BASE_DIR" -type f -printf '%s\t%h\t%f\n' 2>/dev/null | awk -F'\t' -v base="$BASE_DIR/" -v ext_lc="$EXT_LC" '
function human(x) {
    split("B KB MB GB TB PB", u, " ")
    i = 1
    while (x >= 1024 && i < 6) {
        x /= 1024
        i++
    }
    return sprintf("%.2f %s", x, u[i])
}
{
    size = $1
    dir  = $2
    file = tolower($3)

    total_all += size

    if (file !~ ("\\." ext_lc "$"))
        next

    total_ext += size
    total_files++

    if (dir == substr(base, 1, length(base)-1)) {
        top = "."
    } else {
        sub("^" base, "", dir)
        split(dir, a, "/")
        top = a[1]
        if (top == "")
            top = "."
    }

    sum[top] += size
    cnt[top]++
}
END {
    pct = (total_all > 0 ? (total_ext / total_all) * 100 : 0)

    print "Total files:", total_files
    printf "Total size : %s (%.1f%%)\n\n", human(total_ext), pct

    for (d in sum)
        printf "%020d\t%08d\t%s\n", sum[d], cnt[d], d
}' > "$TMPFILE"
) &

WORK_PID=$!
spinner "$WORK_PID"
wait "$WORK_PID"

{
    read -r line1
    read -r line2
    read -r line3

    echo "$line1"
    echo "$line2"
    echo "$line3"
    echo "Size           Files    Folder"

    sort -rn | awk -F'\t' '
    function human(x) {
        split("B KB MB GB TB PB", u, " ")
        i = 1
        while (x >= 1024 && i < 6) {
            x /= 1024
            i++
        }
        return sprintf("%.2f %s", x, u[i])
    }
    {
        folder = ($3 == "." ? "./ (root)" : $3)
        printf "%-14s %-8d %s\n", human($1), $2, folder
    }'
} < "$TMPFILE"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

printf "\nElapsed time: %s\n" "$(format_time "$ELAPSED")"
