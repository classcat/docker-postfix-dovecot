# Postfix Mail Server

Run postfix with **smtp auth**, a **submission port** and **spamassassin** in a docker container.

## Pull Image

    $ sudo docker pull classcat/postfix

## Usage

    $ sudo docker run -it --name (container name) \  
    -p 25:25 -p 587:587 \  
    -v (dir on host):/var/mail \  
    -e hostname=(FQDN of host) -e domainname=(domain name) \  
    -e users=(usr0:uid0:pwd0,usr1:uid1:pwd1) \  
    classcat/postfix

### example)  

    $ sudo docker run -it --name postfix \  
    -p 25:25 -p 587:587 \  
    -v /mail:/var/mail \  
    -e hostname=mailsvr.classcat.com -e domainname=classcat.com \  
    -e users=foo:1001:passwd,foo2:1002:passwd2 \  
    classcat/postfix

---

## Variables

## Known Issues

## Reference

+ [classcat/dovecot](http://registry.hub.docker.com/u/classcat/dovecot/)
