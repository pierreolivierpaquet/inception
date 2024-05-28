#!/bin/sh

apt	update
apt	upgrade
apt	install net-tools -y
apt	install curl -y
apt	install vim -y
apt	install nginx -y

# https://www.youtube.com/watch?v=X3Pr5VATOyA
apt	install openssl -y

mkdir	/etc/nginx/ssl
chmod	700 /etc/nginx/ssl

# Generating key and certificate.
# https://www.openssl.org/docs/manmaster/man1/openssl-req.html
# openssl	req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=CA/ST=Quebec/L=Quebec/O=42Quebec/OU=QuebecNumerique/CN=ppaquet.42.fr"
SSL_SUBJECT="\
/C=CA\
/ST=Quebec\
/L=Quebec\
/O=42Quebec\
/OU=QuebecNumerique\
/CN=ppaquet.42.fr\
/emailAddress=peopaquet@gmail.com"; \
SSL_FOLDER="/etc/nginx/ssl/"; \
SSL_KEYOUT="${SSL_FOLDER}.inception.key"; \
SSL_CRTOUT="${SSL_FOLDER}.inception.crt"; \
openssl	req -new \
			-newkey rsa:2048 \
			-x509 \
			-sha256 \
			-days 365 \
			-nodes \
			-out ${SSL_CRTOUT} \
			-keyout ${SSL_KEYOUT} \
			-subj	${SSL_SUBJECT}
