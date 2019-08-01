# Install your local computer

## Install Ansible 

- under Ubuntu :
```
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

## Install Ansible plugins
 
``` 
ansible-galaxy install nginxinc.nginx
```

## SSH config

To run ansible to remote server, you will need to:
 - Prepare the server, and create an sudo user on ir. Follow [this documentation](./server-install.md).  
 
 - Generate a local SSH key pair (should use ED25519 for better security)
```bash
ssh-keygen -f ~/.ssh/id_ed25519 -t ed25519
```

 - Send the publick key to remote servers: 
```bash
ssh-copy-id -i ~/.ssh/ansible-ed25519.pub username@server_host
```
 - Check every thing works:
```bash
ssh username@server_host
```
