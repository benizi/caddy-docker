FROM alpine:latest as cpanm
ARG build_apks="gcc g++ make git patch perl perl-dev curl wget"
ARG extra_build_apks=""
ARG perl_modules=""
RUN apk update && apk add --no-cache ${build_apks} ${extra_build_apks}
RUN curl -L https://cpanmin.us/ -o /bin/cpanm && chmod +x /bin/cpanm
RUN set -e ; \
  if test -n "${perl_modules}" ; \
  then \
    cpanm ${perl_modules} ; \
    rm -r ~/.cpanm/work ; \
  fi
LABEL builder=true cpanm=true \
  perl_modules="${perl_modules}"

FROM abiosoft/caddy:php
LABEL maintainer "Benjamin R. Haskell <docker@benizi.com>"
ARG perl_apks="perl perl-plack"
ARG perl_modules=""
ARG fcgi_apks="fcgi perl-fcgi perl-fcgi-procmanager"
ARG extra_apks=""
RUN apk add --no-cache ${perl_apks} ${fcgi_apks} ${extra_apks}
COPY --from=cpanm /usr/local /usr/local
LABEL perl_apks="${perl_apks}" \
  fcgi_apks="${fcgi_apks}" \
  extra_apks="${extra_apks}" \
  perl_modules="${perl_modules}"
