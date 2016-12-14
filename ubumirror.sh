#!/bin/bash

if [ ! -z "$1" ]; then
    DIR="$1"
else
    DIR="/var/lib/ubuntu-chatlogs"
fi

[ ! -e "$DIR" -o ! -d "$DIR" ] && rm -rf "$DIR" && mkdir -p "$DIR/{mirror,spool}"

cd "$DIR/mirror"

do_sync() {
    DIR="$1"
    date="$2"
    end="$3"

    while [ "$date" != "$end" ]; do
        wget --quiet -crN -np -l inf -A "*.txt" -R "\#*.html" "http://irclogs.ubuntu.com/$date/"

        for channel_file in $(ls "$DIR/mirror/irclogs.ubuntu.com/$date/"\#*.txt); do
            channel="$(basename "$channel_file" .txt)"

            mkdir -p "$DIR/spool/$channel"
            sourcecodec="$(/usr/local/bin/uchardet "$channel_file" | awk '{print $1}')"
            tmp_file="$(mktemp)"
            final_file="$DIR/spool/$channel/$channel.$(date --date "$date" +'%Y-%m-%d')"
            iconv -f "${sourcecodec}" -t UTF-8 "$channel_file" >"$tmp_file"
            touch "$final_file"; chmod 644 "$final_file"
                    rsync --inplace "$tmp_file" "$final_file"
            rm "$tmp_file"
        done

        echo "$date done."

        date="$(date --date "$date + 1 days" +'%Y/%m/%d')"
    done
}

# sync everything on startup
do_sync "$DIR" "2004/07/05" "$(date --date "tomorrow" +'%Y/%m/%d')"

# run a loop fetching today's logs (30-minute intervals)
while (true); do
    # do yesterday, today, and "tomorrow" to naively cope with timezones because I don't know what timezone the bot runs under
    do_sync "$DIR" "$(date --date "yesterday" +'%Y/%m/%d')" "$(date --date "tomorrow" +'%Y/%m/%d')"
    # wait for 1800 seconds (30 minutes) before running again
    sleep 1800
done
