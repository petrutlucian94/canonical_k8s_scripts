DRBD_MOUNT_DIR=${DRBD_MOUNT_DIR:-"/mnt/drbd0"}

# Disable k8s snap services, we'll need our wrapper that can handle recoveries.
for f in `sudo snap services k8s  | awk 'NR>1 {print $1}'`; do
    echo "disabling snap.$f"
    sudo systemctl disable "snap.$f";
done

sudo crm configure <<EOF
property stonith-enabled=false
property no-quorum-policy=ignore
primitive drbd_res ocf:linbit:drbd params drbd_resource=r0 op monitor interval=29s role=Master op monitor interval=31s role=Slave
ms drbd_master_slave drbd_res meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
primitive fs_res ocf:heartbeat:Filesystem params device=/dev/drbd0 directory=${DRBD_MOUNT_DIR} fstype=ext4
colocation fs_drbd_colo INFINITY: fs_res drbd_master_slave:Master
primitive ha_k8s_failover_service systemd:2ha_k8s_failover op start interval=0 timeout=120 op stop interval=0 timeout=30
order fs_after_drbd mandatory: drbd_master_slave:promote
order failover_after_fs mandatory: fs_res:start ha_k8s_failover_service:start
colocation fs_failover_colo INFINITY: fs_res ha_k8s_failover_service
commit
show
quit
EOF
