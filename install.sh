#!/bin/bash

# stop script if error
set -e

# color codes
RESTORE='\033[0m'
BLACK='\033[00;30m'
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'
LBLACK='\033[01;30m'
LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'
CLEAR='\e[1A\e[K'

# _header colorize the given argument with spacing
function _header {
    printf "\n ${YELLOW}$1${RESTORE}\n"
}

# _cmd for handling commands
function _cmd {
    # empty err.log
    > err.log

    # restore color
    printf "${RESTORE}"

    # check if description is given
    if test -n "$1"; then
        # print description
        printf "  ${LBLACK} ·  ${1} \n${LRED}"
        # check for errors
        if eval "$2" 1> /dev/null 2> err.log; then
            # print success
            printf "  ${CLEAR}${LGREEN} ✓  ${LGREEN}${1}\n"
            return 0 # success
        fi
        printf "  ${CLEAR}${LRED} X  ${1}${LRED}\n"
        while read line; do 
            printf "      ${line}\n"
        done < err.log
        return 1 # failure
    fi

    # check for errors
    if eval "$2" 1> /dev/null 2> err.log; then
        return 0 # success
    fi
    printf "${LRED}"
    while read line; do 
        printf "      ${line}\n"
    done < err.log
    return 1 # failure
} 

# clear terminal
clear

# print logo + information
printf "${YELLOW}
  ▄▄·        ▐ ▄ ·▄▄▄▄  ▄• ▄▌▄▄▄        
 ▐█ ▌▪▪     •█▌▐███▪ ██ █▪██▌▀▄ █·▪     
 ██ ▄▄ ▄█▀▄ ▐█▐▐▌▐█· ▐█▌█▌▐█▌▐▀▀▄  ▄█▀▄ 
 ▐███▌▐█▌.▐▌██▐█▌██. ██ ▐█▄█▌▐█•█▌▐█▌.▐▌
 ·▀▀▀  ▀█▄▀▪▀▀ █▪▀▀▀▀▀•  ▀▀▀ .▀  ▀ ▀█▄▀▪
 ${LBLACK}Hardening Ubuntu 20.04 · ${YELLOW}https://condu.ro
"

# script must be run as root
if [[ $(id -u) -ne 0 ]] ; then printf "\n${LRED} Please run as root${RESTORE}\n\n" ; exit 1 ; fi


# dependencies
_header "Dependencies"
    _cmd "install wget" 'apt-get install wget -y'
    _cmd "install ufw" 'apt-get install wget -y'
    _cmd "install sed" 'apt-get install sed -y'
    _cmd "install git" 'apt-get install git -y'

# updates
_header "Updates"
    _cmd "update" 'apt-get update -y'
    _cmd "upgrade" 'apt-get full-upgrade -y'

# firewall
_header "Firewall"
    _cmd "disable ufw" 'ufw disable'
    _cmd "reset rules" 'echo "y" | sudo ufw reset'
    _cmd "disable logging" 'ufw logging off'
    _cmd "deny incoming" 'ufw default deny incoming'
    _cmd "allow outgoing" 'ufw default allow outgoing'
    _cmd "allow 80/tcp" 'ufw allow 80/tcp'
    _cmd "allow 443/tcp" 'ufw allow 443/tcp'
    printf "  ${YELLOW} ·  Specify SSH port [default 22]: ${RESTORE}"
    read -p "" prompt
    if [[ $prompt != "" ]]; then
        _cmd "${CLEAR}allow ${prompt}/tcp" 'ufw allow ${prompt}/tcp'
        _cmd "update sshd config" 'sed -i "/Port /Id" /etc/ssh/sshd_config'
        _cmd "" 'echo "Port ${prompt}" | sudo tee -a /etc/ssh/sshd_config'
    else 
        _cmd "${CLEAR}allow 22/tcp" 'ufw allow 22/tcp'
    fi
    _cmd "enable ufw" 'ufw --force enable'

# network
_header "Network"
    _cmd "enable cloudflare ns" 'sed -i "/nameserver /Id" /etc/resolv.conf'
    _cmd "" 'echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf'
    _cmd "" 'echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf'

    _cmd "disable ipv6 sysctl" 'sed -i "/net.ipv6.conf.lo.disable_ipv6/Id" /etc/sysctl.conf'
    _cmd "" 'sed -i "/net.ipv6.conf.all.disable_ipv6/Id" /etc/sysctl.conf'
    _cmd "" 'sed -i "/net.ipv6.conf.default.disable_ipv6/Id" /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf'

    _cmd "disable ipv6 ufw" 'sed -i "/ipv6=/Id" /etc/default/ufw'
    _cmd "" 'echo "IPV6=no" | sudo tee -a /etc/default/ufw'

    _cmd "disable ipv6 grub" 'sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub'
    _cmd "" 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub'

    _cmd "ignore icmp echo" 'sed -i "/net.ipv4.icmp_echo_ignore_/Id" /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf'

    _cmd "block syn attacks" 'sed -i "/net.ipv4.tcp_max_syn_backlog/Id" /etc/sysctl.conf'
    _cmd "" 'sed -i "/net.ipv4.tcp_synack_retries/Id" /etc/sysctl.conf'
    _cmd "" 'sed -i "/net.ipv4.tcp_syn_retries/Id" /etc/sysctl.conf'
    _cmd "" 'sed -i "/net.ipv4.tcp_syncookies/Id" /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv4.tcp_syn_retries = 5" | sudo tee -a /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv4.tcp_syncookies = 0" | sudo tee -a /etc/sysctl.conf'

# ntp
_header "NTP"
    _cmd "remove ntp.ubuntu.com" 'sed -i "/NTP=/Id" /etc/systemd/timesyncd.conf'
    _cmd "add time.cloudflare.com" 'echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf'
    _cmd "" 'echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf'

# system
_header "System"
    _cmd "disable empty ssh pass" 'sed -i "/PermitEmptyPasswords/Id" /etc/ssh/sshd_config'
    _cmd "" 'echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config'

    _cmd "hide kernel pointers" 'sed -i "/kernel.kptr_restrict/Id" /etc/sysctl.conf'
    _cmd "" 'echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf'

    _cmd "disable journal" 'systemctl stop systemd-journald.service'
    _cmd "" 'systemctl mask systemd-journald.service'

    _cmd "disable snapd" 'systemctl stop snapd.service'
    _cmd "" 'systemctl mask snapd.service'

    _cmd "disable multipathd" 'systemctl stop multipathd 2>&1'
    _cmd "" 'systemctl mask multipathd'

    _cmd "disable qemu-gest" 'apt-get remove qemu-guest-agent -y'
    _cmd "" 'apt-get remove --auto-remove qemu-guest-agent -y' 
    _cmd "" 'apt-get purge qemu-guest-agent -y' 
    _cmd "" 'apt-get purge --auto-remove qemu-guest-agent -y'

    _cmd "disable apt-daily" 'systemctl stop apt-daily.service'
    _cmd "" 'systemctl disable apt-daily.service' 
    _cmd "" 'systemctl stop apt-daily-upgrade.timer' 
    _cmd "" 'systemctl disable apt-daily-upgrade.timer' 
    _cmd "" 'systemctl stop apt-daily.timer' 
    _cmd "" 'systemctl disable apt-daily.timer'

    # _cmd "disable neworkd" 'apt-get remove networkd-dispatcher -y'
    # _cmd "" 'systemctl stop systemd-networkd.service' 
    # _cmd "" 'systemctl disable systemd-networkd.service'

    _cmd "disable cron" 'systemctl disable cron'
    _cmd "" 'systemctl stop cron'

    _cmd "remove policykit" 'apt-get remove policykit-1 -y'
    _cmd "" 'apt-get autoremove policykit-1 -y' 
    _cmd "" 'apt-get purge policykit-1 -y' 
    _cmd "" 'apt-get autoremove --purge policykit-1 -y'

    _cmd "remove accountsservice" 'service accounts-daemon stop'
    _cmd "" 'apt remove accountsservice -y'

# golang
_header "Golang"
    _cmd "download" 'wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz'
    _cmd "unpack" 'tar -C /usr/local -xzf go.tar.gz'
    _cmd "export path" 'echo "export GOROOT=/usr/local/go" >> /etc/profile'
    _cmd "" 'echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile'
    _cmd "reload path" 'source /etc/profile' 
    _cmd "remove go.tar.gz" 'rm go.tar.gz'

# cleanup
_header "Cleanup"
    # _cmd "purge" 'apt-get remove --purge -y'
    _cmd "remove man" 'rm -rf /usr/share/man/*'
    _cmd "delete logs" 'find /var/log -type f -delete'
    _cmd "autoremove" 'apt-get autoremove -y'
    _cmd "autoclean" 'apt-get autoclean -y'
    # _cmd "clean" 'apt-get clean && sudo apt-get --purge autoremove -y'

# reload
_header "Reload"
    _cmd "reload sysctl" 'sysctl -p'
    _cmd "reload grub2" 'update-grub2'
    _cmd "reload timesyncd" 'systemctl restart systemd-timesyncd'
    _cmd "reload ssh" 'service ssh restart'

# remove err.log
sudo rm err.log

# reboot
printf "\n${YELLOW} Do you want to reboot [Y/n]? ${RESTORE}"
read -p "" prompt
if [[ $prompt == "y" || $prompt == "Y" ]]; then
    sudo reboot
fi

# exit
exit
