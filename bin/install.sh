#!/bin/bash

NFS_DRIVER_VER="0.34"
PYG_BASE_DIR="/opt/pygmalion"
PYG_WORK_DIR="$PYG_BASE_DIR/workspace"
PYG_INST_LOG="$PYG_BASE_DIR/install.log"

usages() {
    echo "Usages : install.sh [master|worker]"
    echo "    master <MASTER_NODE_IP> : install master node"
    echo "    worker <MASTER_NODE_IP> <TOKEN> : install worker node"
    echo ""
    exit 1
}

install_prepare() {
    echo "prepare installation"
    if [ -f $PYG_INSTALL_LOG ]; then
        echo "pygmalion already installed"
        exit 1
    fi
    mkdir -p $PYG_BASE_DIR
    mkdir -p $PYG_WORK_DIRs
    touch $PYG_INST_LOG
}

uninstall_prepare() {
    echo "prepare uninstallation"
    if [ ! -f $PYG_INSTALL_LOG ]; then
        echo "pygmalion is not installed"
        exit 1
    fi
}

install_packages() {
    echo "install packages"
    apt install -y docker.io nfs-common >> $PYG_INST_LOG
    systemctl restart docker >> $PYG_INST_LOG
    systemctl enable docker >> $PYG_INST_LOG
    docker pull jzidea/pygics:latest >> $PYG_INST_LOG
}

install_drivers() {
    echo "install drivers"
    curl https://github.com/ContainX/docker-volume-netshare/releases/download/v$NFS_DRIVER_VER/docker-volume-netshare_$NFS_DRIVER_VER_amd64.deb -o /opt/pygmalion/netshare.deb >> $PYG_INST_LOG
    dpkg -i /opt/pygmalion/netshare.deb >> $PYG_INST_LOG
    systemctl restart docker-volume-netshare >> $PYG_INST_LOG
    systemctl enable docker-volume-netshare >> $PYG_INST_LOG
}

install_nfs_server() {
    echo "install nfs server"
    apt install -y nfs-kernel-server >> $PYG_INST_LOG
    mkdir -p $PYG_WORK_DIR
    echo "" >> /etc/exports
    echo "/opt/pygmalion/workspace    *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
    systemctl restart nfs-kernel-server >> $PYG_INST_LOG
    systemctl enable nfs-kernel-server >> $PYG_INST_LOG
}

install_services() {
    echo "install services"
    install_packages()
    install_drivers()
}

install_post() {
    echo "install post work"
}

uninstall_post() {
    echo "uninstall post work"
    mv $PYG_INST_LOG $PYG_INST_LOG.bak
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
    
    install_prepare
    #install_nfs_server
    #install_services
    install_post
    
    docker swarm leave --force >> $PYG_INST_LOG 2>&1
    local token=`docker swarm init --advertise-addr $master_ip | grep "\-\-token" | awk '{print $2}'`
    echo "install master node finished"
    echo "do typing followed to install on worker"
    echo ""
    echo "    install.sh worker $master_ip $token"
    echo ""
    echo "enjoy pygmalion :)"
}

uninstall_master() {
    echo "uninstall master node"
    
    docker swarm leave --force >> $PYG_INST_LOG 2>&1
    asdf
}

install_worker() {
    echo "install worker node"
    local master_ip=$1
    local token=$2
    
    install_prepare
    #install_services
    install_post
    
    docker swarm leave --force >> $PYG_INST_LOG 2>&1
    docker swarm join --token $token $master_ip:2377 >> $PYG_INST_LOG
}

uninstall_worker() {
    echo "uninstall worker node"
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

