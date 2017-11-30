FROM ubuntu:16.04 as uchardet

RUN apt-get update && apt-get install -yqq build-essential libicu-dev ruby ruby-dev && apt-get clean
RUN gem install uchardet

FROM ubuntu:16.04
RUN apt-get update && apt-get install -yqq wget rsync ruby libicu55 && apt-get clean
COPY --from=uchardet /usr/local/bin/uchardet /usr/local/bin/uchardet
COPY --from=uchardet /var/lib/gems /var/lib/gems

RUN mkdir -p /var/lib/ubuntu-chatlogs /usr/share/ubuntu-chatlogs
WORKDIR /var/lib/ubuntu-chatlogs
COPY . /usr/share/ubuntu-chatlogs

CMD [ "/bin/bash", "/usr/share/ubuntu-chatlogs/ubumirror.sh" ]
