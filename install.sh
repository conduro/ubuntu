#!/bin/bash

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

# _cmd for handling commands
function _cmd {
    # set variables
    DESCRIPTION=$1
    CMD=$2

    # get correct line length
    LINE="───────────────────────────────────"
    LINE=${LINE:${#DESCRIPTION}}

    # restore color
    printf "${RESTORE}"

    # check if description is given
    if test -n "$1"; then
        # print description
        printf "  ${LBLACK}─ ${DESCRIPTION} \n${LRED}"
        # check if for errors
        if eval "$CMD" > /dev/null; then
            # print success
            printf "  \e[1A\e[K${LBLACK}─ ${LGREEN}${DESCRIPTION} ${LBLACK}${LINE} ${LGREEN}[✓]\n"
            return 0 # success
        fi 
        return 1 # failure
    fi

    # check if for errors
    printf "${LRED}" # potential errors should be red
    if eval "$CMD" > /dev/null; then
        return 0 # success
    fi
    return 1 # failure
} 

# _header colorize the given argument with spacing
function _header {
    printf "\n ${YELLOW}$1${RESTORE}\n"
}

# _clearline overrides the previous line
function _clearline {
    printf "\e[1A\e[K"
}

# clear terminal
clear

# print logo + information
printf "${YELLOW}
  ▄▄·        ▐ ▄ ·▄▄▄▄  ▄• ▄▌▄▄▄        
 ▐█ ▌▪▪     •█▌▐███▪ ██ █▪██▌▀▄ █·▪     
 ██ ▄▄ ▄█▀▄ ▐█▐▐▌▐█· ▐█▌█▌▐█▌▐▀▀▄  ▄█▀▄ 
 ▐███▌▐█▌.▐▌██▐█▌██. ██ ▐█▄█▌▐█•█▌▐█▌.▐▌
 ·▀▀▀  ▀█▄▀▪▀▀ █▪▀▀▀▀▀•  ▀▀▀ .▀  ▀ ▀█▄▀▪ v1.0.0

${LBLACK} Ubuntu 20.04 Hardening - ${YELLOW}visit https://condu.ro${RESTORE} 

"

# updates
_header "Updates"
    _cmd "update" 'sudo apt-get update -y' && \
    _cmd "upgrade" 'sudo apt-get full-upgrade -y'
    _cmd "autoremove" "sudo apt-get autoremove"
    _cmd "autoclean" "sudo apt-get autoclean"

# dependencies
_header "Dependencies"
    _cmd "install wget" 'sudo apt-get install wget -y'
    _cmd "install ufw" 'sudo apt-get install ufw -y'
    _cmd "install sed" 'sudo apt-get install sed -y'
    _cmd "install git" 'sudo apt-get install git -y'

# firewall
_header "Firewall"
    _cmd "disable ufw" 'sudo ufw disable' && \
    _cmd "reset rules" 'echo "y" | sudo ufw reset' && \
    _cmd "disable logging" 'sudo ufw logging off' && \
    _cmd "deny incoming" 'sudo ufw default deny incoming' && \
    _cmd "allow outgoing" 'sudo ufw default allow outgoing' && \
    _cmd "allow 80/tcp" 'sudo ufw allow 80/tcp' && \
    _cmd "allow 443/tcp" 'sudo ufw allow 443/tcp'
    printf "  ${YELLOW}─ Specify SSH port [default 22]: ${RESTORE}"
    read -p "" prompt
    if [[ $prompt != "" ]]; then
        _clearline
        _cmd "allow ${prompt}/tcp" 'sudo ufw allow ${prompt}/tcp'
        _cmd "update sshd config" 'sudo sed -i "/Port /Id" /etc/ssh/sshd_config' && \
        _cmd "" 'echo "Port ${prompt}" | sudo tee -a /etc/ssh/sshd_config'
    else 
        _clearline
        _cmd "allow 22/tcp" 'sudo ufw allow 22/tcp'
    fi
    _cmd "enable ufw" 'sudo ufw --force enable'

# network
_header "Network"
    _cmd "enable cloudflare ns" 'sudo sed -i "/nameserver /Id" /etc/resolv.conf' && \
    _cmd "" 'echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf' && \
    _cmd "" 'echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf'

    _cmd "disable ipv6 sysctl" 'sudo sed -i "/net.ipv6.conf.lo.disable_ipv6/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv6.conf.all.disable_ipv6/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv6.conf.default.disable_ipv6/Id" /etc/sysctl.conf'
    _cmd "" 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf'

    _cmd "disable ipv6 ufw" 'sudo sed -i "/ipv6=/Id" /etc/default/ufw' && \
    _cmd "" 'echo "IPV6=no" | sudo tee -a /etc/default/ufw'

    _cmd "disable ipv6 grub" 'sudo sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub' && \
    _cmd "" 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub'

    _cmd "ignore icmp echo" 'sudo sed -i "/net.ipv4.icmp_echo_ignore_/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo 1 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_all'

    _cmd "block syn attacks" 'sudo sed -i "/net.ipv4.tcp_max_syn_backlog/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_synack_retries/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_syn_retries/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_syncookies/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.tcp_syn_retries = 5" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo "net.ipv4.tcp_syncookies = 0" | sudo tee -a /etc/sysctl.conf'

# ntp
_header "NTP"
    _cmd "disable ntp.ubuntu.com" 'sudo sed -i "/NTP=/Id" /etc/systemd/timesyncd.conf' && \
    _cmd "enable time.cloudflare.com" 'echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf' && \
    _cmd "" 'echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf'

# system
_header "System"
    _cmd "disable empty ssh pass" 'sudo sed -i "/PermitEmptyPasswords/Id" /etc/ssh/sshd_config' && \
    _cmd "" 'echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config'
    _cmd "disable sysctl logs" 'sudo sed -i "/kernel.dmesg_restrict/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf'
    _cmd "disable rsyslog" 'sudo systemctl stop syslog.socket rsyslog.service' && \
    _cmd "" 'sudo service rsyslog stop' && \
    _cmd "" 'sudo systemctl disable rsyslog'
    _cmd "hide kernel pointers" 'sudo sed -i "/kernel.kptr_restrict/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf'

# golang
_header "Golang"
    _cmd "download" 'sudo wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz' && \
    _cmd "unpack" 'sudo tar -C /usr/local -xzf go.tar.gz' && \
    _cmd "export path" 'export PATH="/path/to/directory/go/bin/:$PATH" >> ~/.bashrc' && \
    _cmd "reload path" 'source ~/.bashrc'  && \
    _cmd "remove go.tar.gz" "sudo rm go.tar.gz"

# cleanup
_header "Cleanup"
    _cmd "apt clean" "sudo apt-get clean"
    _cmd "reload sysctl" 'sudo sysctl -p'
    _cmd "realod ssh" "sudo service ssh restart"
    _cmd "reload grub2" 'sudo update-grub2 2>&1'
    _cmd "reload timesyncd" 'sudo systemctl restart systemd-timesyncd'

# reboot
printf "\n${YELLOW} Do you want to reboot [Y/n]? ${RESTORE}"
read -p "" prompt
if [[ $prompt == "y" || $prompt == "Y" ]]; then
    sudo reboot
fi

# exit
exit
