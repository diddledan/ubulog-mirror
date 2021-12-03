#!/bin/bash

if [ ! -z "$1" ]; then
    DIR="$1"
else
    DIR="/var/lib/ubuntu-chatlogs"
fi

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
            --wait=2 --random-wait --retry-connrefused \
            -A "*.txt" -R "\#*.html" "http://irclogs.ubuntu.com/$date/"

        for channel_file in $(ls "$DIR/mirror/irclogs.ubuntu.com/$date/"\#*.txt); do
            channel="$(basename "$channel_file" .txt)"

            mkdir -p "$DIR/spool/$channel"
            sourcecodec="$(/usr/bin/uchardet "$channel_file" | awk '{print $1}')"
            tmp_file="$(mktemp)"
            final_file="$DIR/spool/$channel/$channel.$(date --date "$date" +'%Y-%m-%d')"
            iconv -f "${sourcecodec}" -t UTF-8 "$channel_file" >"$tmp_file"
            touch "$final_file";
            # chmod 644 "$final_file"
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

