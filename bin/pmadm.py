#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Created on 2018. 10. 15.
@author: Hyechurn Jang, <hyjang@cisco.com>
'''

from __future__ import print_function
import os
import sys
import array
import fcntl
import socket
import struct
import docker
import argparse

NFS_DRIVER_VER = '0.34'
PYG_BASE_DIR = '/opt/pygmalion'
PYG_WORK_DIR = PYG_BASE_DIR + '/workspace'
PYG_INST_LOG = PYG_BASE_DIR + '/install.log'
PYG_TOKEN = PYG_BASE_DIR + '/token'

def command(title, cmd, fne=False):
    print(title, end='')
    if os.system('%s >> %s 2>&1' % (cmd, PYG_INST_LOG)):
        print(' --> [ Failed ]')
        if fne: exit(1)
    print(' --> [ OK ]')

def prepare_env():
    print('PREPARE ENVIRONMENT')
    if os.path.exists(PYG_INST_LOG):
        print('pygmalion already installed')
        exit(1)
    print('create directories', end='')
    os.system('mkdir -p %s' % PYG_BASE_DIR)
    os.system('mkdir -p %s' % PYG_WORK_DIR)
    os.system('touch %s' % PYG_INST_LOG)
    print(' --> [ OK ]')

def install_nfs_server():
    print('INSTALL NFS SERVER')
    command('install nfs server', 'apt install -y nfs-kernel-server')
    if os.system('cat /etc/exports | grep pygmalion'):
        command('register workspace', 'echo "/opt/pygmalion/workspace    *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports')    
    command('restart nfs server', 'systemctl restart nfs-kernel-server')
    command('register nfs service', 'systemctl enable nfs-kernel-server')
    
def install_packages():
    print('INSTALL PACKAGES')
    command('install docker & nfs client', 'apt install -y docker.io nfs-common')
    command('restart docker', 'systemctl restart docker')
    command('register docker service', 'systemctl enable docker')
    command('download docker nfs driver', 'curl https://github.com/ContainX/docker-volume-netshare/releases/download/v%s/docker-volume-netshare_%s_amd64.deb -o /opt/pygmalion/netshare.deb' % (NFS_DRIVER_VER, NFS_DRIVER_VER))
    command('install docker nfs driver', 'dpkg -i /opt/pygmalion/netshare.deb')
    command('download pygics image', 'docker pull jzidea/pygics:latest')

def get_ips():
    max_possible = 128
    bytes = max_possible * 32
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    names = array.array('B', '\0' * bytes)
    outbytes = struct.unpack('iL', fcntl.ioctl(s.fileno(), 0x8912, struct.pack('iL', bytes, names.buffer_info()[0])))[0]
    namestr = names.tostring()
    result = {}
    for i in range(0, outbytes, 40):
        name = namestr[i:i+16].split('\0', 1)[0]
        ip = namestr[i+20:i+24]
        ip = str(ord(ip[0])) + '.' + str(ord(ip[1])) + '.' + str(ord(ip[2])) + '.' + str(ord(ip[3]))
        result[ip] = name
    return result

def master_swarm():
    print('initialize docker swarm', end='')
    os.system('docker swarm leave --force >> /dev/null 2>&1')
    if os.system("""docker swarm init --advertise-addr $master_ip | grep "\-\-token" | awk '{print $2}' >> %s""" % PYG_TOKEN):
        print(' --> [ Failed ]')
        exit(1)
    print(' --> [ OK ]')

def worker_swarm(ip, token):
    print('initialize docker swarm', end='')
    os.system('docker swarm leave --force >> /dev/null 2>&1')
    if os.system('docker swarm join --token %s %s:2377 >> %s 2>&1' % (token, ip, PYG_INST_LOG)):
        print(' --> [ Failed ]')
        exit(1)
    print(' --> [ OK ]')

def install_master(ip):
    print('INSTALL MASTER NODE')
    ips = get_ips().keys()
    if ip not in ips:
        print('%s not in local IP addresses' % ip)
        print('local IP list : %s' % ', '.join(ips))
        exit(1)
    
    prepare_env()
    install_nfs_server()
#     install_packages()
#     master_swarm()
    
    print('MASTER INSTALLED')

def install_worker(ip, token):
    print('INSTALL WORKER NODE')
    
    prepare_env()
#     install_packages()
#     worker_swarm(ip, token)
    
    print('WORKER INSTALLED')

def exit_node():
    print('EXIT NODE')
    if not os.path.exists(PYG_INST_LOG):
        print('pygmalion is not installed')
        exit(1)
    
    print('remove all containers', end='')
    try:
        dc = docker.from_env()
        conts = dc.containers.list()
        for cont in conts:
            cont.remove(v=True, force=True)
        dc.close()
    except: print(' --> [ Failed ]')
    else: print(' --> [ OK ]')
    
    command('leave docker swarm', 'docker swarm leave --force')
    
    print('move log to old', end='')
    os.system('mv %s %s.old' % (PYG_INST_LOG, PYG_INST_LOG))
    print(' --> [ OK ]')
    print('FINISHED')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Pygmalion Admin Tool')
    parser.add_argument('command', required=True, help='[ init | join | exit ]')
    args = parser.parse_args()
    commnad = args.commnad
    if command == 'init':
        parser.add_argument('master', required=True, help='Master IP Address or Hostname')
        args = parser.parse_args()
        master = args.master
        install_master(master)
    elif command == 'join':
        parser.add_argument('master', required=True, help='Master IP Address or Hostname')
        parser.add_argument('token', required=True, help='Token Generated on Master')
        args = parser.parse_args()
        master = args.master
        token = args.token
        install_worker(master, token)
    elif command == 'exit':
        exit_node()
