FROM ubuntu

RUN apt-get update && apt-get install -yqq build-essential libicu-dev rsync ruby ruby-dev wget && apt-get clean
RUN gem install uchardet

RUN mkdir -p /var/lib/ubuntu-chatlogs /usr/share/ubuntu-chatlogs
WORKDIR /var/lib/ubuntu-chatlogs
COPY . /usr/share/ubuntu-chatlogs

CMD [ "/bin/bash", "/usr/share/ubuntu-chatlogs/ubumirror.sh" ]