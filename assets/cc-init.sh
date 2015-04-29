#!/bin/bash

########################################################################
# ClassCat/Postfix Asset files
# maintainer: Masashi Okumura < masao@classcat.com >
########################################################################

## last modified : 29-apr-15 ##

###############
### POSTFIX ###
###############

function proc_postfix_basic () {
  echo "$domainname" > /etc/mailname

  postconf -e myhostname=$hostname
  postconf -e mydestination=$domainname,$hostname,localhost.localdomain,localhost

  # enable a submission port. postconf should be used.
  sed -i -e "s/^#submission/submission/" /etc/postfix/master.cf 

  # See http://www.postfix.org/wip.html
  postconf -F '*/*/chroot=n'
}

function add_accounts () {
  echo $users | tr , \\n > /var/tmp/users
  while IFS=':' read -r _user _id _pwd; do
    useradd -u $_id -s /usr/sbin/nologin $_user
    echo -e "${_pwd}\n${_pwd}" | passwd $_user
  done < /var/tmp/users
  rm /var/tmp/users
}

function proc_postfix_smtp_auth () {
  postconf -e smtpd_sasl_auth_enable=yes
  postconf -e smtpd_sasl_local_domain=$domainname
  postconf -e broken_sasl_auth_clients=yes
  postconf -e smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination

  cat >> /etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF

  echo $users | tr , \\n > /var/tmp/users
  while IFS=':' read -r _user _id _pwd; do
    echo $_pwd | saslpasswd2 -p -c -u $domainname $_user
  done < /var/tmp/users
  rm /var/tmp/users

  chown postfix.sasl /etc/sasldb2
}

function proc_postfix () {
  proc_postfix_basic
  add_accounts
  proc_postfix_smtp_auth
}


####################
### SPAMASSASSIN ###
####################

function proc_spamassassin () {
  mkdir /var/log/spamassassin
  chown debian-spamd:debian-spamd /var/log/spamassassin

  #sed -i -e "s/^ENABLED\s*=\s*0/ENABLED=1/" /etc/default/spamassassin
  #sed -i -e "s/^CRON\s*=\s*0/CRON=1/" /etc/default/spamassassin

  # smtp       inet  n       -       n       -       -       smtpd
  sed -i -e "s/^smtp\s*inet\s*n\s*\-\s*n\s*\-\s*\-\s*smtpd\s*/smtp       inet  n       -       n       -       -       smtpd -o content_filter=spamassassin/" /etc/postfix/master.cf


  echo 'spamassassin unix -     n       n       -       -       pipe' >> /etc/postfix/master.cf
  echo '    user=debian-spamd argv=/usr/bin/spamc -f -e'            >> /etc/postfix/master.cf
  echo '    /usr/sbin/sendmail -oi -f ${sender} ${recipient}'       >> /etc/postfix/master.cf
}


##################
### SUPERVISOR ###
##################
# See http://docs.docker.com/articles/using_supervisord/

function proc_supervisor () {
  cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:spamassassin]
command=/opt/cc-spamassassin.sh

[program:postfix]
command=/opt/cc-postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n -c3
EOF

  cat >> /opt/cc-spamassassin.sh <<EOF
#!/bin/bash
service spamassassin start
tail -F /var/log/spamassassin/spamd.log
EOF

  chmod +x /opt/cc-spamassassin.sh

  cat >> /opt/cc-postfix.sh <<EOF
#!/bin/bash
/usr/sbin/postfix start
tail -F /var/log/mail.log
EOF

  chmod +x /opt/cc-postfix.sh
}


proc_postfix
proc_spamassassin
proc_supervisor

# /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

exit 0
