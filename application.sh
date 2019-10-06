#!/usr/bin/env bash


# TODO: Use here-strings
MUSIC_DIR="$HOME/Music"

_to_api_url() {
    local -r sc_url="$1" # For example, https://soundcloud.com/mayanwarriorofficial/sainte-vie-bm-2019
    echo "$(curl -s "https://api.soundcloud.com/resolve?url=$sc_url&client_id=$SC_CLIENT_ID" | jq -r '.location')"
}

# _get_cdn_url stream_url
_get_cdn_url() {
    local stream_url="$1?client_id=$SC_CLIENT_ID" # Like https://api.soundcloud.com/tracks/683167353/stream
    echo "$(curl -s "$stream_url" | jq -r '.location')"
}

# download_track SC_URL [DEST_DIR]
download_track() {
    local -r sc_url="$1"
    local -r dest_dir="${2:-"$MUSIC_DIR"}"
    local -r api_url="$(_to_api_url "$sc_url")" # client_id is already there
    local -r track_info="$(curl -s "$api_url")"
    local -r stream_url="$(jq -r '.stream_url' <<< "$track_info")?client_id=$SC_CLIENT_ID"
    local -r cdn_url="$(curl -s "$stream_url" | jq -r ".location")"
    local -r file_name="$(jq -r '.title' <<< "$track_info").mp3"
    local -r file_path="$dest_dir/$file_name"

    curl -# "$cdn_url" -o "$file_path"
}

download_favorites() {
    local -r sc_url="$1" # Like https://soundcloud.com/ste-vie-1
    local -r dest_dir="${2:-"$MUSIC_DIR"}"

    local -r api_url="$(_to_api_url "$sc_url")" # client_id is already there
    local -r user_id="$(curl "$api_url" | jq -r '.id')" # TODO: Explain why
    local -r favorites_url="https://api.soundcloud.com/users/$user_id/favorites?client_id=$SC_CLIENT_ID"
    local -r favourites="$(curl "$favorites_url")"
    local -r favs="$(jq -r '.[] | select(.kind == "track") | {title:.title,url:.stream_url} | tostring' <<< "$favourites")"

    declare -a tracks
    readarray -t tracks <<< "$favs"

    for track in "${tracks[@]}"; do
        stream_url="$(jq -r '.url' <<< "$track")"
        cdn_url="$(_get_cdn_url "$stream_url")"
        file_name="$(jq -r '.title' <<< "$track").mp3"
        file_path="$dest_dir/$file_name"

        curl -# "$cdn_url" -o "$file_path"
    done
}

$@