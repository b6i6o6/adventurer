#! /bin/bash
# Download quest text and replace the newlines if it is not already in cache
TYPE=$1
if [[ ! -z $1 ]]; then
    TYPE="$TYPE:";
fi
NAME=$(cat page_uri.tmp)
PAGE_NAME="$TYPE$NAME"
PAGE_FILE="./Cache/$PAGE_NAME.txt"
if [[ ! -f $PAGE_FILE ]]; then
    curl -sS "https://wow.gamepedia.com/$PAGE_NAME?action=raw" | tr '\n' '€' > $PAGE_FILE
fi
cat $PAGE_FILE
