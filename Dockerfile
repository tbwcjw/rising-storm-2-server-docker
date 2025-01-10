FROM cm2network/steamcmd:latest

USER root

ADD ./rs2server.sh /
RUN chmod +x /rs2server.sh

RUN apt update && apt -y install --no-install-recommends wget locales procps && \
    touch /etc/locale.gen && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    apt -y install --reinstall ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt update && apt -y install gnupg2 software-properties-common libcurl4

RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
RUN wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

RUN apt update && apt -y install --install-recommends xvfb winehq-staging && \
    apt -y --purge remove software-properties-common gnupg2 && \
    apt -y autoremove && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

USER steam
ENV HOME /home/steam
ENV WINEPREFIX $HOME/wine
ENV WINEARCH win64
ENV WINEDEBUG -all
ENV DISPLAY :0:0
ENV WORKDIR /home/steam
ADD rs2server.txt /home/steam/rs2server.txt

ENTRYPOINT ["/rs2server.sh"]
CMD ["/bin/bash"]
