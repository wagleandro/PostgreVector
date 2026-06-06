FROM alpine:3.22

RUN apk add --no-cache ca-certificates curl postgresql-client tar xz \
  && mkdir -p /etc/postgrest

ARG POSTGREST_VERSION=14.13
RUN curl -L -o /tmp/postgrest.tar.xz \
  "https://github.com/PostgREST/postgrest/releases/download/v${POSTGREST_VERSION}/postgrest-v${POSTGREST_VERSION}-linux-static-x86-64.tar.xz" \
  && tar -xJf /tmp/postgrest.tar.xz -C /usr/local/bin \
  && chmod +x /usr/local/bin/postgrest \
  && rm -rf /var/cache/apk/* /tmp/postgrest.tar.xz

COPY postgrest.conf /etc/postgrest.conf
COPY init-db.sql /etc/postgrest/init-db.sql
COPY init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh

EXPOSE 10000
CMD ["/usr/local/bin/init-db.sh"]



