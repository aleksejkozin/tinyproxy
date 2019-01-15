FROM debian:jessie as builder
MAINTAINER r.gilles@telekom.de

RUN    apt-get update   \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        make \
        automake \
        autoconf \
        g++ \
        asciidoc \
        git \
    && rm -rf /var/lib/apt/lists/*

ENV TINYPROXY_VERSION=master

RUN git clone -b ${TINYPROXY_VERSION} --depth=1 https://github.com/tinyproxy/tinyproxy.git /tmp/tinyproxy \
  && cd /tmp/tinyproxy \
  && ./autogen.sh \
  && ./configure --enable-transparent --prefix="" \
  && make \
  && make install \
  && mkdir -p /var/log/tinyproxy \
  && cd / \
  && rm -rf /tmp/tinyproxy \
  && apt-get remove -y --purge make automake autoconf g++ asciidoc git \
  && apt-get autoremove -y \
  && apt-get autoclean

FROM debian:jessie
RUN useradd tinyproxy
COPY --from=0 /bin/tinyproxy /bin/tinyproxy

COPY entry.sh entry.sh
ENTRYPOINT ["/entry.sh"]

COPY tinyproxy.conf /etc/tinyproxy.conf

RUN sed -i -e 's|^Logfile.*|Logfile "/logs/tinyproxy.log"|; \
        s|^PidFile.*|PidFile "/logs/tinyproxy.pid"|' /etc/tinyproxy.conf \
        && echo "Allow  0.0.0.0/0" >> /etc/tinyproxy.conf

RUN mkdir /logs
VOLUME    /logs

EXPOSE 8888
EXPOSE 443
