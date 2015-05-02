FROM classcat/ubuntu:trusty
MAINTAINER Masashi Okumura <masao@classcat.com>

ENV DEBIAN_FRONTEND noninteractive

RUN  bash -c 'debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet site"' \
  && bash -c 'debconf-set-selections <<< "postfix postfix/mailname string mail.example.com"'

RUN apt-get update && apt-get -y install postfix sasl2-bin spamassassin spamc \
  dovecot-core dovecot-pop3d dovecot-imapd

WORKDIR /opt
ADD assets/cc-init.sh /opt/cc-init.sh

ADD assets/spamassassin /etc/default/spamassassin

ADD assets/local.cf /etc/spamassassin/local.cf

ADD assets/dovecot /etc/init.d/dovecot

EXPOSE 25 587 110 143

CMD /opt/cc-init.sh; /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
