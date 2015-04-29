FROM ubuntu:trusty
MAINTAINER Masashi Okumura <masao@classcat.com>

# docker run -d -p 25:25 -p 587:587 \
#   -e hostname=hostname -e domainname=domainname \
#   masao/postfix-sv
# Set multiple user credentials: -e smtp_user=user1:pwd1,user2:pwd2,...,userN:pwdN

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y install supervisor postfix sasl2-bin

ADD assets/cc-init.sh /opt/cc-init.sh

ADD assets/supervisord.conf /etc/supervisor/supervisord.conf

CMD /opt/cc-init.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf

#ENTRYPOINT ["/opt/startup.sh"]

