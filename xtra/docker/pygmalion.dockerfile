FROM ubuntu:latest

COPY ./pygmalion /usr/bin/pygmalion
COPY ./pygics /usr/bin/pygics
RUN chmod 755 /usr/bin/pygd
RUN mkdir -p /opt/pygmalion /opt/pygmalion/workspace
RUN apt update && apt install -y python3
WORKDIR /opt/pygmalion/workspace
CMD ["/usr/bin/pygmalion"]