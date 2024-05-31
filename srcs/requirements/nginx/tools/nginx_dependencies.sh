#!/bin/sh

# Updates.
apt	update
apt	upgrade

# # Debugging tools.
# apt	install net-tools -y
# apt	install curl -y
# apt	install vim -y

apt	install nginx -y

# https://www.youtube.com/watch?v=X3Pr5VATOyA
apt	install openssl -y

mkdir	/etc/nginx/ssl
chmod	700 /etc/nginx/ssl

# Generating key and certificate.
# https://www.openssl.org/docs/manmaster/man1/openssl-req.html
SSL_SUBJECT="\
/C=CA\
/ST=Quebec\
/L=Quebec\
/O=42Quebec\
/OU=QuebecNumerique\
/CN=${WP_DOMAIN_NAME}\
/emailAddress=$(cat ${WP_EMAIL_ADMIN_FILE})"; \
SSL_FOLDER="/etc/nginx/ssl/"; \
SSL_KEYOUT="${SSL_FOLDER}.inception.key"; \
SSL_CRTOUT="${SSL_FOLDER}.inception.crt"; \
openssl	req -new \
			-newkey rsa:4096 \
			-x509 \
			-sha3-512 \
			-days 365 \
			-nodes \
			-out ${SSL_CRTOUT} \
			-keyout ${SSL_KEYOUT} \
			-subj	${SSL_SUBJECT}
