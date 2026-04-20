#!/bin/bash

show_help() {
    cat << 'EOF'
Usage:
  ./deus.sh /absolute/path/to/folder

Description:
  Scans the specified folder recursively, counts files by extension,
  calculates total size, and shows aggregated usage by top-level folders.

Arguments:
  /absolute/path/to/folder   Absolute path to the target folder

Options:
  -h, --help                 Show this help message

Example:
  ./deus.sh /home/user/Downloads
EOF
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

BASE_DIR="$1"

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

read -rp "Enter the file extension (e.g. mp3, pdf): " EXT

EXT="${EXT#.}"

if [[ -z "$EXT" ]]; then
    echo "Error: file extension is not specified."
    exit 1
fi

# Remove trailing slash if present
BASE_DIR="${BASE_DIR%/}"

find "$BASE_DIR" -type f -iname "*.$EXT" -printf '%s\t%h\n' 2>/dev/null | awk -F'\t' -v base="$BASE_DIR/" '
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
    total += $1
    files++

    dir = $2

    if (dir == substr(base, 1, length(base)-1)) {
        top = "."
    } else {
        sub("^" base, "", dir)
        split(dir, a, "/")
        top = a[1]
        if (top == "")
            top = "."
    }

    sum[top] += $1
    cnt[top]++
}
END {
    print "Total files:", files
    print "Total size :", human(total)
    print ""
    for (d in sum)
        printf "%020d\t%08d\t%s\n", sum[d], cnt[d], d
}' | {
    read -r a
    read -r b
    read -r c
    echo "$a"
    echo "$b"
    echo "$c"
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
}
