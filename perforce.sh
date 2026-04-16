#!/bin/bash
set -e

# change user-id of perforce user to match the host user-id
usermod -u $PERFORCE_UID perforce
# change group-id of perforce group to match the host group-id
groupmod -og $PERFORCE_GID perforce

# if the perforce config file doesn't exist, run the config script
if [ ! -f /etc/perforce/p4dctl.conf.d/$SERVER_ID.conf ]; then
    echo "No perforce config file found, running config script..."
    # copy saved perforce template config file
    cp /opt/perforce/p4d.template /etc/perforce/p4dctl.conf.d/p4d.template
    # generate a random master password
    echo "Generating random master password..."
    MASTER_PASSWORD=$(pwgen -s 32 1)
    echo "Master password: $MASTER_PASSWORD"

    CASE_OPTION=""
    if [ "$CASE_INSENSITIVE" == "1" ] || [ "$CASE_INSENSITIVE" == "true" ]; then
        CASE_OPTION+="--case 1"
    fi

    UNICODE_OPTION=""
    if [ "$UNICODE" == "1" ] || [ "$UNICODE" == "true" ]; then
        UNICODE_OPTION+="--unicode"
    fi

    /opt/perforce/sbin/configure-helix-p4d.sh $SERVER_ID -n $CASE_OPTION $UNICODE_OPTION -p ssl:$P4PORT -r $P4ROOT -u $MASTER_USER -P $MASTER_PASSWORD
fi

# if there are no SSL certificates, generate them
export P4SSLDIR=$P4ROOT/root/ssl
if [ ! -f $P4SSLDIR/certificate.txt ]; then
    echo "No SSL certificates found, re-generating them..."
    su - perforce -c "export P4SSLDIR=$P4SSLDIR && p4d -Gc"
fi

chown -R perforce:perforce $P4ROOT
chown -R perforce:perforce /dbs
cd /dbs
p4dctl start $SERVER_ID
tail -F -n 100 $P4ROOT/logs/log
