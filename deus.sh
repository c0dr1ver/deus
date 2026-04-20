#!/bin/bash

read -rp "Enter the absolute path to the folder: " BASE_DIR
read -rp "Enter the file extension (e.g. mp3, pdf): " EXT

if [[ "$BASE_DIR" != /* ]]; then
    echo "Error: you must specify an absolute path, e.g. /home/bitrix/www/upload"
    exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: directory does not exist: $BASE_DIR"
    exit 1
fi

EXT="${EXT#.}"

if [[ -z "$EXT" ]]; then
    echo "Error: file extension is not specified"
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
