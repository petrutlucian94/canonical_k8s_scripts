#!/bin/bash

SCRIPTDIR=`dirname ${BASH_SOURCE[0]}`

sudo cp $SCRIPTDIR/*.service /etc/systemd/system/

sudo systemctl enable 2ha_k8s

sudo systemctl daemon-reload

# Disable k8s snap services, we'll need our wrapper that can handle recoveries.
for f in `sudo snap services k8s  | awk 'NR>1 {print $1}'`; do
    echo "disabling snap.$f"
    sudo systemctl disable "snap.$f";
done