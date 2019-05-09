#!/bin/bash

# To change the access keys on a server for a list of users and
# mail the keys to their email addresses.

#USER="alpha beta gamma delta omega sigma theta"
USER="test"
DOMAIN="gmail.com"

for U in $USER
do
	EMAIL="$U@$DOMAIN"

	# If email differs for any user
	[ "$U" == "delta" ] && EMAIL="delta@yahoo.in"

	sudo su - "$U" bash -c '
	  ssh-keygen -t rsa
	  cp .ssh/id_rsa.pub .ssh/authorized_keys '

	cat SUBJECT.txt | mail -a /home/$U/.ssh/id_rsa -s 'Server Access Key' $EMAIL 
	#sudo su - "$u" bash -c ' cd .ssh && mv id_rsa.ORG id_rsa '
	[ "$?" -eq 0 ] && echo "$U:$EMAIL Key sent... Success" || echo "Some error in mail command... Failure" 
done
