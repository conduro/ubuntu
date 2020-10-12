# Conduro 
Linux is well-known for being one of the most secure operating systems available. But that doesn't mean you can count on it to be as secure as possible right out of the box. Conduro (_Hardening in Latin_) will automate this process to ensure your platform is secure.

This script is designed to be executed on a freshly installed **Ubuntu Server 20.04** server.

# Getting Started

```bash
wget -O - https://condu.ro/install.sh | sudo bash
```
![](https://i.imgur.com/RvdJQjU.gif)

# What does it do?
The purpose of Conduro is to optimize and secure your system to run web applications. It does this by disabling unnecessary services, bootstrapping your firewall, secure your system settings and other things. Continue reading if you want to know exactly what's being executed.

#### install dependencies
```bash
apt-get install wget sed git -y
```

#### update system
Keeping the system updated is vital before starting anything on your system. This will prevent people to use known vulnerabilities to enter in your system.
```bash
apt-get update -y && apt-get full-upgrade -y
```

#### update nameservers
We change the default nameservers to cloudflare because https://www.dnsperf.com/#!dns-resolvers
```bash
truncate -s0 /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
```
#### update ntp server
```bash
sed -i "/NTP=/Id" /etc/systemd/timesyncd.conf
echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf
echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf
```

#### block syn attacks
```bash
sed -i "/net.ipv4.tcp_max_syn_backlog/Id" /etc/sysctl.conf
sed -i "/net.ipv4.tcp_synack_retries/Id" /etc/sysctl.conf
sed -i "/net.ipv4.tcp_syn_retries/Id" /etc/sysctl.conf
sed -i "/net.ipv4.tcp_syncookies/Id" /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syn_retries = 5" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
```

#### hide kernel pointers
```bash
sed -i "/kernel.kptr_restrict/Id" /etc/sysctl.conf
echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf
```

#### disable empty ssh passwords
```bash
sed -i "/PermitEmptyPasswords/Id" /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config
```

#### disable ipv6
```bash
sed -i "/net.ipv6.conf.lo.disable_ipv6/Id" /etc/sysctl.conf
sed -i "/net.ipv6.conf.all.disable_ipv6/Id" /etc/sysctl.conf
sed -i "/net.ipv6.conf.default.disable_ipv6/Id" /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

sed -i "/ipv6=/Id" /etc/default/ufw
echo "IPV6=no" | sudo tee -a /etc/default/ufw

sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub
```

#### disable icmp pings
```bash
sed -i "/net.ipv4.icmp_echo_ignore_/Id" /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf
```

#### disable journal
```bash
systemctl stop systemd-journald.service
systemctl disable systemd-journald.service
systemctl mask systemd-journald.service
```

#### disable snapd
```bash
systemctl stop snapd.service
systemctl disable snapd.service
systemctl mask snapd.service
```

#### disable multipathd
```bash
systemctl stop multipathd
systemctl disable multipathd
systemctl mask multipathd
```

#### disable cron
```bash
systemctl stop cron
systemctl disable cron
systemctl mask cron
```

#### disable fwupd
```bash
systemctl stop fwupd.service
systemctl disable fwupd.service
systemctl mask fwupd.service
```

#### disable rsyslog
```bash
systemctl stop rsyslog.service
systemctl disable rsyslog.service
systemctl mask rsyslog.service
```

#### disable qemu-guest
```bash
apt-get remove qemu-guest-agent -y
apt-get remove --auto-remove qemu-guest-agent -y
apt-get purge qemu-guest-agent -y
apt-get purge --auto-remove qemu-guest-agent -y
```

#### disable policykit
```bash
apt-get remove policykit-1 -y
apt-get autoremove policykit-1 -y
apt-get purge policykit-1 -y
apt-get autoremove --purge policykit-1 -y
```

#### disable accountsservice
```bash
service accounts-daemon stop
apt remove accountsservice -y
```

#### install golang
```bash
wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile
source /etc/profile
rm go.tar.gz
```

#### configure firewall
```bash
ufw disable
echo "y" | sudo ufw reset
ufw logging off
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp

# optional prompt to change ssh port
    ufw allow ${prompt}/tcp
    sed -i "/Port /Id" /etc/ssh/sshd_config
    echo "Port ${prompt}" | sudo tee -a /etc/ssh/sshd_config
# defaults to port 22
    ufw allow 22/tcp

ufw --force enable
```

#### delete man
```bash
rm -rf /usr/share/man/*
```

#### delete system logs
```bash
find /var/log -type f -delete
```

#### autoremove
```bash
apt-get autoremove -y
apt-get autoclean -y
```

#### reload system
```bash
sysctl -p
```

#### reload grub
```bash
update-grub2
```

#### reload timesync
```bash
systemctl restart systemd-timesyncd
```

#### reload ssh
```bash
service ssh restart
```