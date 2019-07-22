#!/bin/bash

# Usage: ./cassandraBackup.sh -h [HOSTNAME] -u [USERNAME] -k [KEYSPACE_NAME] -s [SSH_TYPE] -f [PEM_FILE_PATH] -b [S3_BUCKET_PATH]
# Example: ./cassandraBackup.sh -h java.senpiper.com -u ubuntu -f /home/ubuntu/senpiper-java-staging.pem -s 0 -k user

# Named Parameters
# h: hostname of the cassandra node
# u: username of the node (in case ssh is required)
# k: keyspace to be backed up
# s: ssh_type 
# 	SSH TYPES
# 		1. key-based: Enter 0
# 		2. password-based: Enter 1
# Else the cassandra lies on the same node as the script
# f: pem file in case of key based ssh
# b: AWS S3 Bucket folder path to upload the backup file, if applicable (also, would require access to bucket)

# Defining the paramters
while getopts "h:u:s:f:k:" option
do
	case $option in
		h) HOST=$OPTARG ;;
		u) USER=$OPTARG ;;
		s) SSH_TYPE=$OPTARG ;;
		f) KEY_PATH=$OPTARG ;;
		b) S3BUCKET_PATH=$OPTARG ;;
		k) KEYSPACE=$OPTARG ;;
		*) echo 'Usage: ./cassandraBackup.sh -h HOST -u USER -k KEYSPACE -s SSH_KEY_OR_PASSWORD_BASED -f PEM_KEY_PATH -b AWS_S3_BUCKET_PATH' ;;
	esac
done

#echo -e "host: $HOST \nuser: $USER \nkeyspaceName: $KEYSPACE \n$SSH_TYPE | $KEY_PATH"

# function to execute the commands
execution() {

	DATE='date +%Y%m%d_%H%M%S'

	# Taking backup of keyspace schema
	SCHEMA_FILE="schema_${KEYSPACE}_$($DATE)"
	cqlsh -e "DESC $KEYSPACE" > /tmp/$SCHEMA_FILE
	
	# Cleaning up old snapshots before taking a new snapshot
	nodetool clearsnapshot $KEYSPACE
	
	# Taking snapshot of the keyspace
	nodetool snapshot -t $($DATE) $KEYSPACE
	
	# Creating tar of the backup file on local disk
	SNAPSHOT_TAR="$KEYSPACE.tar.gz"
	FILES_IN_SNAPSHOTS="find $KEYSPACE -type f"
	KEYSPACE_DIR='/var/lib/cassandra/data'

	cd $KEYSPACE_DIR
	tar -zcf /tmp/$SNAPSHOT_TAR `$FILES_IN_SNAPSHOTS`
	cd /tmp
	tar -zcf cqlsh_${KEYSPACE}_$($DATE).tar.gz $SCHEMA_FILE $SNAPSHOT_TAR

	# Uploading the backup to aws s3 bucket
	echo "UPLOAD_TO_AWSBUCKET=\"aws s3 sync /tmp/cqlsh_${KEYSPACE}_$($DATE).tar.gz s3://${S3BUCKET}\""
}

# execution
# exit

case $SSH_TYPE	in
	0)
		ssh -i $KEY_PATH -o StrictHostKeyChecking=no $USER@$HOST "KEYSPACE=$KEYSPACE; $(typeset -f); execution \"$KEYSPACE\" " ;;
	1)	
		ssh -o StrictHostKeyChecking=no $USER@$HOST "KEYSPACE=$KEYSPACE; $(typeset -f); execution \"$KEYSPACE\" " ;;
	*)
		execution
		;;
esac
