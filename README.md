T-NSA
=====

To setup the gitlab VM and prepare the other ones with ansible:
```
1. Start the 4 VMs
2. Prepare the Gitlab VM

    2.1 Install docker
        sudo apt-get update
        sudo apt-get install docker.io
        
    2.2 Create script that starts gitlab container
        nano ~/startGitlab.sh
        
        With the following content: 
        docker run --detach --hostname gitlab.example.com --publish 443:443 --publish 80:80 --name gitlab --restart always --volume /srv/gitlab/config:/etc/gitlab --volume /srv/gitlab/logs:/var/log/gitlab --volume /srv/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:latest
        
    2.3 Start Gitlab server
        sudo chmod +x ./startGitlab.sh
        sudo sh startGitlab.sh
        
    2.4 Install ansible
        sudo apt-add-repository ppa:ansible/ansible
        sudo apt-get update --fix-missing
        sudo apt-get install ansible -y
        
    2.5 Generate SSH keys (default, just press ENTER)
        ssh-keygen
        
    2.6 Setup other VMs for the connection (this section is to reproduce on each other VM)
        2.6.1 Add `AllowRootLogin yes` to /etc/ssh/sshd_config
        2.6.2 Explicitely set the root password with `passwd` as root user
        2.6.3 Reboot the VM with `reboot`
        
    2.7 Add the Gitlab ssh public key on all the other VMs as authorized_key
        ssh-copy-id root@<ENTER_VM_IP_ADDRESS>
        
    2.8 Copy the content of the `ansible` directory of this repo into /etc/ansible
    
    2.9 Setup the VMs
        sudo ansible-playbook /etc/ansible/install_and_setup_mysql.yml -c paramiko
    
```

