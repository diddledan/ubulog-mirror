FROM ubuntu:20.04

WORKDIR /var/lib/ubuntu-chatlogs

RUN apt-get update && \
    apt-get install -yqq \
        libicu55 \
        rsync \
        uchardet \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists

RUN useradd -u 1000 -U -M mirroruser
RUN mkdir -p /var/lib/ubuntu-chatlogs /usr/share/ubuntu-chatlogs && \
    chown 1000:1000 /var/lib/ubuntu-chatlogs
COPY . /usr/share/ubuntu-chatlogs

USER mirroruser
CMD [ "/bin/bash", "/usr/share/ubuntu-chatlogs/ubumirror.sh" ]
