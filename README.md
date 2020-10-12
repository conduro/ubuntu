# Conduro 
Hardening (_conduro_) Ubuntu 20.04

## Getting Started

```bash
bash <(wget -qO- https://condu.ro/install.sh)
```
![](https://i.imgur.com/522Kwxk.gif)

### Dependencies
Installing and updating packages that are required for hardening.

```bash
apt-get install wget -y
apt-get install wget -y
apt-get install sed -y
apt-get install git -y
```

### Updates
Keeping the system updated is vital before starting anything on your system. This will prevent people to use known vulnerabilities to enter in your system.

```bash
apt-get update -y
apt-get full-upgrade -y
```

### Firewall
We reset all firewall rules and only add port `80`, `443` and custom SSH port ( defaults to `22` if left empty )
```bash
ufw disable
ufw reset
ufw logging off
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow <promt_ssh_port>/tcp
ufw --force enable
```

### Network
We change the default nameservers to cloudflare because https://www.dnsperf.com/#!dns-resolvers
```bash
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
```
Disabling IPv6 in both sysctl, ufw and grub
```bash
echo "IPV6=no" | sudo tee -a /etc/default/ufw

echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub
```
Disable icmp echo ( ping )
```bash
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf
echo 1 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_all
```
Block syn attacks
```bash
echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syn_retries = 5" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 0" | sudo tee -a /etc/sysctl.conf
```
Change NTP server to cloudflare
```bash
echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf
echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf
```

### System
This will disable system logs, hide kernel pointers, ignore empty ssh passwords and disable snapd.
```bash
echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config

echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf
echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf

systemctl mask systemd-journald.service
systemctl stop systemd-journald.service

systemctl mask snapd.service
systemctl stop snapd.service
```

### Install Golang
It will install the latest Golang version and add to PATH
```bash
wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile
source /etc/profile
rm go.tar.gz
```

### Cleanup
Free disk space
```bash
# apt-get remove --purge -y software-properties-common
rm -rf /usr/share/man/*
find /var/log -type f -delete
# apt-get clean && apt-get --purge autoremove

apt-get autoremove -y
apt-get autoclean -y
```

### Reload
Reload modified services
```bash
sysctl -p
service ssh restart
update-grub2
systemctl restart systemd-timesyncd
```

