FROM ubuntu

RUN apt-get update && apt-get install -yqq rsync wget && apt-get clean

RUN mkdir -p /var/lib/ubuntu-chatlogs
WORKDIR /var/lib/ubuntu-chatlogs
COPY . /var/lib/ubuntu-chatlogs

CMD [ "/bin/bash", "/var/lib/ubuntu-chatlogs/ubumirror.sh" ]