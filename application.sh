#!/usr/bin/env bash

CLIENT_ID=""

_to_api_url() {
    local -r sc_url="$1" # For example, https://soundcloud.com/mayanwarriorofficial/sainte-vie-bm-2019
    echo "$(curl -s "https://api.soundcloud.com/resolve?url=$sc_url&client_id=$CLIENT_ID" | jq -r '.location')"
}

download_track() {
    local -r sc_url="$1"
    local -r api_url="$(_to_api_url "$sc_url")" # client_id is already there
    
    local -r track_info="$(curl -s "$api_url")"
    local -r title="$(echo "$track_info" | jq -r '.title')"
    local -r stream_url="$(echo "$track_info" | jq -r '.stream_url')?client_id=$CLIENT_ID"
    
    local -r cdn_url="$(curl -s "$stream_url" | jq -r ".location")"
    local -r file_name="$title.mp3"

    curl -# "$cdn_url" -o "$file_name"
}

$@