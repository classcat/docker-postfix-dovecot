#!/bin/bash

# masao

###############
### POSTFIX ###
function proc_postfix_basic () {
  echo "$domainname" > /etc/mailname

  postconf -e myhostname=$hostname
  postconf -e mydestination=$domainname,$hostname,localhost.localdomain,localhost

  # enable a submission port.
  sed -i -e "s/^#submission/submission/" /etc/postfix/master.cf 

  # See http://www.postfix.org/wip.html
  postconf -F '*/*/chroot=n'
}

function add_accounts () {
  echo $smtp_user | tr , \\n > /var/tmp/passwd
  while IFS=':' read -r _user _id _pwd; do
    useradd -u $_id -p $_pwd -s /sbin/nologin $_user
  done < /var/tmp/passwd
  rm /var/tmp/passwd
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

  echo $smtp_user | tr , \\n > /var/tmp/passwd
  while IFS=':' read -r _user _id _pwd; do
    echo $_pwd | saslpasswd2 -p -c -u $domainname $_user
  done < /var/tmp/passwd

  chown postfix.sasl /etc/sasldb2
}

function proc_postfix () {
  proc_postfix_basic
  add_accounts
  proc_postfix_smtp_auth
}

##################
### SUPERVISOR ###
# See http://docs.docker.com/articles/using_supervisord/
function proc_supervisor () {
  cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:postfix]
command=/opt/cc-postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n -c3
EOF

  cat >> /opt/cc-postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF

  chmod +x /opt/cc-postfix.sh
}


proc_postfix
proc_supervisor

exit 0
