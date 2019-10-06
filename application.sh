#!/usr/bin/env bash

MUSIC_DIR="$HOME/Music"

_to_api_url() {
    local -r sc_url="$1" # For example, https://soundcloud.com/mayanwarriorofficial/sainte-vie-bm-2019
    echo "$(curl -s "https://api.soundcloud.com/resolve?url=$sc_url&client_id=$SC_CLIENT_ID" | jq -r '.location')"
}

# download_track SC_URL [DEST_DIR]
download_track() {
    local -r sc_url="$1"
    local -r dest_dir="${2:-"$MUSIC_DIR"}"
    local -r api_url="$(_to_api_url "$sc_url")" # client_id is already there
    local -r track_info="$(curl -s "$api_url")"
    local -r stream_url="$(echo "$track_info" | jq -r '.stream_url')?client_id=$SC_CLIENT_ID"
    local -r cdn_url="$(curl -s "$stream_url" | jq -r ".location")"
    local -r file_name="$(echo "$track_info" | jq -r '.title').mp3"
    local -r file_path="$dest_dir/$file_name"

    curl -# "$cdn_url" -o "$file_path"
}

$@