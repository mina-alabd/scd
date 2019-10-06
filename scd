#!/usr/bin/env bash -x

MUSIC_DIR="$HOME/Music"

__info() {
    local -r message="$1"
    echo "$message"
}

__get_api_url() {
    local -r sc_url="$1" # Like https://soundcloud.com/mayanwarriorofficial/sainte-vie-bm-2019
    echo "$(curl -s "https://api.soundcloud.com/resolve?url=$sc_url&client_id=$SC_CLIENT_ID" | jq -r '.location')"
}

__from_api() {
    local -r sc_url="$1"
    local -r api_url="$(__get_api_url "$sc_url")"

    echo "$(curl -s "$api_url")"
}

__get_cdn_url() {
    local stream_url="$1" # Like https://api.soundcloud.com/tracks/683167353/stream
    echo "$(curl -s "$stream_url?client_id=$SC_CLIENT_ID" | jq -r '.location')"
}

_get_track() {
    local -r sc_url="$1" # Like https://soundcloud.com/mayanwarriorofficial/sainte-vie-bm-2019
    echo "$(__from_api "$sc_url" | jq -r '{title:.title,stream_url:.stream_url}')"
}

# download_track SC_URL [DEST_DIR]
download_track() {
    local -r sc_url="$1"
    local -r dest_dir="${2:-"$MUSIC_DIR"}"

    local -r track="$(_get_track "$sc_url")"
    _download_track "$track" "$dest_dir"
}

_get_user_id() {
    local -r sc_url="$1"
    echo "$(__from_api "$sc_url" | jq -r '.id')" # TODO: Explain why
}

__get_favorites_url() {
    local -r sc_url="$1"
    local -r user_id="$(_get_user_id "$sc_url")"
    echo "https://api.soundcloud.com/users/$user_id/favorites?client_id=$SC_CLIENT_ID"
}

_get_favorite_tracks() {
    local -r QUERY='.[] | select(.kind == "track") | {title:.title,stream_url:.stream_url} | tostring'

    local -r sc_url="$1" # Like https://soundcloud.com/mayanwarriorofficial
    local -r url="$(__get_favorites_url "$sc_url")"

    echo "$(curl -s "$url" | jq -r "$QUERY")"
}

_download_track() {
    local -r track="$1" # A JSON object like {"title":"...", "stream_url":"..."}
    local -r dest_dir="${2:-"$MUSIC_DIR"}"
    
    local -r title="$(jq -r '.title' <<< "$track")"
    local -r stream_url="$(jq -r '.stream_url' <<< "$track")"

    local -r dest_path="$dest_dir/$title.mp3" #TODO: Sanitize
    local -r cdn_url="$(__get_cdn_url "$stream_url")"

    __info "Downloading $dest_path ..."
    curl -# "$cdn_url" -o "$dest_path"
}

download_favorite_tracks() {
    local -r sc_url="$1" # Like https://soundcloud.com/ste-vie-1
    
    declare -a tracks
    readarray -t tracks <<< "$(_get_favorite_tracks "$sc_url")"

    for track in "${tracks[@]}"; do
        _download_track "$track"
    done
}

main() {
    local -r sc_url="$1"
    
    local -r api_url="$(__get_api_url "$sc_url")"
    if [[ $api_url == "https://api.soundcloud.com/tracks"* ]]; then
        download_track "$sc_url"
    elif [[ $api_url == "https://api.soundcloud.com/users"* ]]; then
        download_favorite_tracks "$sc_url"
    fi
}

main "$@"