# Conduro Ubuntu 20.04
Linux is well-known for being one of the most secure operating systems available. But that doesn't mean you can count on it to be as secure as possible right out of the box. Conduro (_Hardening in Latin_) will automate this process to ensure your platform is secure.

> ⚠ We recommend to not execute this script on servers with existing firewall configurations.

# Getting Started
This script is designed to be executed on a freshly installed **Ubuntu Server 20.04** server.

```bash
wget -O - https://condu.ro/install.sh | sudo bash
```
![](https://i.imgur.com/RvdJQjU.gif)

# What does it do?
The purpose of Conduro is to optimize and secure your system to run web applications. It does this by disabling unnecessary services, bootstrapping your firewall, secure your system settings and other things. Continue reading if you want to know exactly what's being executed.

#### update dependencies
```bash
apt-get install wget sed git -y
```

#### update system
Keeping the system updated is vital before starting anything on your system. This will prevent people to use known vulnerabilities to enter in your system.
```bash
apt-get update -y && apt-get full-upgrade -y
```

#### update golang
```bash
rm -rf /usr/local/go
wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile
source /etc/profile
rm go.tar.gz
```

#### update nameservers
We change the default nameservers to cloudflare because https://www.dnsperf.com/#!dns-resolvers
```bash
truncate -s0 /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
```
#### update ntp servers
```bash
truncate -s0 /etc/systemd/timesyncd.conf
echo "[Time]" | sudo tee -a /etc/systemd/timesyncd.conf
echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf
echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf
```

#### update sysctl.conf
```conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0 
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0 
net.ipv6.conf.default.accept_redirects = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Hide kernel pointers
kernel.kptr_restrict = 2

# Enable panic on OOM
vm.panic_on_oom = 1

# Reboot kernel ten seconds after OOM
kernel.panic = 10
```

#### update sshd_config
```conf
# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes

# Depending on your 2FA option, you may need to enable some of these options, but they should be disabled by default
ChallengeResponseAuthentication no
PasswordAuthentication no

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# Disable connection multiplexing which can be used to bypass authentication
MaxSessions 1

# Block client 10 minutes after 3 failed login attempts
MaxAuthTries 3
LoginGraceTime 10

# Do not allow empty passwords
PermitEmptyPasswords no

# Enable PAM authentication
UsePAM yes

# Disable Kerberos based authentication
KerberosAuthentication no
KerberosGetAFSToken no
KerberosOrLocalPasswd no
KerberosTicketCleanup yes
GSSAPIAuthentication no
GSSAPICleanupCredentials yes

# Disable user environment forwarding
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitUserRC no
PermitUserEnvironment no

# We want to log all activity
LogLevel INFO
SyslogFacility AUTHPRIV

# What messages do you want to present your users when they log in?
Banner none
PrintMotd no
PrintLastLog yes

# override default of no subsystems
Subsystem sftp  /usr/lib/openssh/sftp-server
```

#### update firewall
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

#### disable ipv6
```bash
sed -i "/ipv6=/Id" /etc/default/ufw
echo "IPV6=no" | sudo tee -a /etc/default/ufw

sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub
```


#### disable system logging
```bash
systemctl stop systemd-journald.service
systemctl disable systemd-journald.service
systemctl mask systemd-journald.service

systemctl stop rsyslog.service
systemctl disable rsyslog.service
systemctl mask rsyslog.service
```

#### delete system logs
```bash
find /var/log -type f -delete
rm -rf /usr/share/man/*
```

#### autoremove
```bash
apt-get autoremove -y
apt-get autoclean -y
```

#### reload system
```bash
sysctl -p
update-grub2
systemctl restart systemd-timesyncd
service ssh restart
```
