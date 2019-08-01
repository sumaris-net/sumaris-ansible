# Prepare a server to work with ansible

## Update the distribution to latest version

```bash
apt update
apt upgrade
apt install vim sudo python python3
```

## Create your user and configure sudo

```bash
adduser -shell /bin/bash blavenie
usermod -aG sudo blavenie
passwd blavenie
```

Then configure user to need no password
```bash
visudo
```
 - Add, at the end
```
:wq!:x:
```

### Configure the DNS

Your node should be accessible via DNS thanks to the following address : 

```
[hostname].domain.com
```

### Verify that sudo is working as intended

```bash
ssh blavenie@yourserver
sudo -s
exit
exit
```

### Disable ssh root login

```bash
sed -i s/PermitRootLogin .*/PermitRootLogin no/g /etc/ssh/sshd_config
service ssh restart
```

## Add your node to ansible conf

Once your node is configured, you can add it to `hosts.yml` file and `host_vars` directory.

In the `hosts.yml` file, you need to define the following items : 

```yml
yourserver:
  hostname: server.domain.com
  ansible_port: 2200
```

Some more vars can be added later depending on the roles ran on the server.

