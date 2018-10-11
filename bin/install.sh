#!/bin/bash

NFS_DRIVER_VER="0.34"

usages() {
    echo "Usages : install.sh [master|worker]"
    echo "    master : install master node"
    echo "    worker : install worker node"
    echo ""
    exit 1
}

install_base() {
    apt install -y docker.io nfs-common
    curl https://github.com/ContainX/docker-volume-netshare/releases/download/v$NFS_DRIVER_VER/docker-volume-netshare_$NFS_DRIVER_VER_amd64.deb -o /opt/pygmalion/netshare.deb
    dpkg -i /opt/pygmalion/netshare.deb
    systemctl restart docker docker-volume-netshare
    systemctl enable docker docker-volume-netshare
    docker pull jzidea/pygics:latest
}

install_master() {
    echo "install master node"
    apt install -y nfs-kernel-server
    mkdir -p /opt/pygmalion
    mkdir -p /opt/pygmalion/workspace
    cat <<EOF>> /etc/exports
/opt/pygmalion/workspace    *(rw,sync,no_root_squash,no_subtree_check)
EOF
    systemctl restart nfs-kernel-server
    systemctl enable nfs-kernel-server
    install_base
}

install_worker() {
    echo "install worker node"
    install_base
}

CMD=$1
case $CMD in
    master)
        install_master
        ;;
    worker)
        install_worker
        ;;
    *)
        usages
        ;;
esac

