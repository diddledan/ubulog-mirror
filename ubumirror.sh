#!/bin/bash

if [ ! -z "$1" ]; then
    DIR="$1"
else
    DIR="/var/lib/ubuntu-chatlogs"
fi

# Ensure the timezone is UTC.
export TZ=UTC

quit() {
    echo "$1"
    exit 1
}

if [ ! -e "$DIR" -o ! -d "$DIR" ]; then
    rm -rf "$DIR" && mkdir -p "$DIR" || quit "unable to make '$DIR'"
fi
if [ ! -e "$DIR/mirror" -o ! -d "$DIR/mirror" ]; then
    rm -rf "$DIR/mirror" && mkdir -p "$DIR/mirror" || quit "unable to make '$DIR/mirror'"
fi
if [ ! -e "$DIR/spool" -o ! -d "$DIR/spool" ]; then
    rm -rf "$DIR/spool" && mkdir -p "$DIR/spool" || quit "unable to make '$DIR/spool'"
fi

cd "$DIR/mirror" || quit "unable to cd into '$DIR/mirror'"

do_sync() {
    DIR="$1"
    date="$2"
    end="$3"

    while [ "$date" != "$end" ]; do
        wget --quiet -c -l inf -m -N -np -t inf \
            --random-wait --retry-connrefused \
            -A "*.txt" -R "*.html" "http://irclogs.ubuntu.com/$date/"

        for channel_file in "$DIR/mirror/irclogs.ubuntu.com/$date/#"*.txt; do
            channel="$(basename "$channel_file" .txt)"

            mkdir -p "$DIR/spool/$channel"
            sourcecodec="$(/usr/bin/uchardet "$channel_file" | awk '{print $1}')"
            tmp_file="$(mktemp)"
            final_file="$DIR/spool/$channel/$channel.$(date --date "$date" +'%Y-%m-%d')"
            if [ "$sourcecodec" = "unknown" ]; then
                cp "$channel_file" "$tmp_file"
            else
                iconv -f "${sourcecodec}" -t UTF-8 "$channel_file" >"$tmp_file"
            fi
            touch "$final_file";
            # chmod 644 "$final_file"
            rsync --inplace "$tmp_file" "$final_file"
            rm "$tmp_file"
        done

        echo "$date done."
        echo "$date" > last_sync_date

        date="$(date --date "$date + 1 days" +'%Y/%m/%d')"
    done
}

# sync everything on startup
start_date="2004/07/05"
if [ -f last_sync_date ]; then
    start_date=$(cat last_sync_date)
fi
do_sync "$DIR" "$start_date" "$(date --date "yesterday 23:59" +'%Y/%m/%d')"

# run a loop fetching today's logs (30-minute intervals)
while (true); do
    # do yesterday only
    do_sync "$DIR" "$(date --date "yesterday 00:00" +'%Y/%m/%d')" "$(date --date "yesterday 23:59" +'%Y/%m/%d')"
    # wait for 24 hours before running again
    sleep 86400
done

