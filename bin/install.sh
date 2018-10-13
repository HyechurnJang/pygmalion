#!/bin/bash

NFS_DRIVER_VER="0.34"

usages() {
    echo "Usages : install.sh [master|worker]"
    echo "    master <MASTER_NODE_IP> : install master node"
    echo "    worker <MASTER_NODE_IP> <TOKEN> : install worker node"
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
    local master_ip=$1
    local ips=`ip a | grep inet | awk '{print $2}' | sed -e "s/\/.*//g" | paste -sd"|"`
    if [ -z $master_ip ]; then
        usages
    fi
    if ! [[ "$master_ip" =~ ($ips) ]]; then
        echo "$master_ip not in local ip list"
        usages
    fi
#    apt install -y nfs-kernel-server
#    mkdir -p /opt/pygmalion
#    mkdir -p /opt/pygmalion/workspace
#    cat <<EOF>> /etc/exports
#/opt/pygmalion/workspace    *(rw,sync,no_root_squash,no_subtree_check)
#EOF
#    systemctl restart nfs-kernel-server
#    systemctl enable nfs-kernel-server
#    install_base
    docker swarm leave --force > /dev/null 2>&1
    local token=`docker swarm init --advertise-addr $master_ip | grep "\-\-token" | awk '{print $2}'`
    echo "install master node finished"
    echo "do typing followed to install on worker"
    echo "    install.sh $master_ip $token"
    echo ""
}

install_worker() {
    echo "install worker node"
    local master_ip=$1
    local token=$2
#    install_base
    docker swarm leave --force > /dev/null 2>&1
    docker swarm join --token $token $master_ip:2377
}

CMD=$1
case $CMD in
    master)
        install_master $2
        ;;
    worker)
        install_worker $2 $3
        ;;
    *)
        usages
        ;;
esac

