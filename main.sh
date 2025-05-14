#!/bin/bash

UPLOAD_DIR="${1:-.}"
OUTPUT_PHP="output.php"
TMP_FILE=$(mktemp)
FILENAME_EXT="flac|alac|aac|opus|aif|m4a|mp3|aac|wav|ogg|opus|wma|aiff|alac"

{
    echo "<?php"
    echo "\$files = ["
} > "$OUTPUT_PHP"

shopt -s nocaseglob nullglob
for file in "$UPLOAD_DIR"/*; do
    [ -f "$file" ] || continue

    ext="${file##*.}"
    if [[ ! "$ext" =~ ^($FILENAME_EXT)$ ]]; then
        echo "skipped(non audio): $(basename "$file")"
        continue
    fi

    filename="$(basename "$file")"
    echo "uploading: $filename..."

    DEBUG_LOG=$(mktemp)

    response=$(curl -s -w "%{http_code}" -o "$DEBUG_LOG" \
        -F "reqtype=fileupload" \
        -F "fileToUpload=@$file" \
        https://catbox.moe/user/api.php)

    http_code="$response"
    body=$(cat "$DEBUG_LOG")

    if [[ "$http_code" == "200" && "$body" =~ ^https://files\.catbox\.moe/ ]]; then
        echo "uploaded: $filename"
        {
            echo "    ["
            echo "        'name' => '$filename',"
            echo "        'mirrors' => ["
            echo "            ['name' => 'catbox', 'url' => '$body']"
            echo "        ]"
            echo "    ],"
        } >> "$TMP_FILE"
    else
        echo "didnt upload: $filename"
        echo ">code: $http_code"
        echo ">body: $body"
    fi

    rm "$DEBUG_LOG"
done
shopt -u nocaseglob nullglob

sed '$ s/],$/]/' "$TMP_FILE" >> "$OUTPUT_PHP"

echo "];" >> "$OUTPUT_PHP"
echo "?>" >> "$OUTPUT_PHP"

rm "$TMP_FILE"
echo "out saved to $OUTPUT_PHP"
``