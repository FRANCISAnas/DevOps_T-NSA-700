T-NSA
=====

To setup the gitlab VM and prepare the other ones with ansible:
```

1. Setup and start the 4 VMs

    1.1 Install terraform on your computer
    
    1.2 Install the Azure CLI on your computer
    
    1.3 Create a subscription in Azure Cloud Services from Microsoft
    
    1.4 Change the subscription ID with yours in the main.tf file (line 34)

    1.5 Change the ssh key to add to the VM with yours in the main.tf file (line 10)
    
    1.6 Login to Azure using the azure CLI with: az login
    
    1.7 Apply the script with terraform
    
    1.8 Once done, your VMs are ready to be used

2. Configure the SSH access

    2.1 Login to the Gitlab VM (IP address can be find on the azure portal)

    2.2 Generate an ssh key
        ssh-keygen -t rsa -N "" -f /home/jonas/.ssh/id_rsa

    2.3 This point is to repeat on the 3 other VMs
    
        2.3.1 Login to the VM

        2.3.2 Generate an SSH key
            ssh-keygen -t rsa -N "" -f /home/jonas/.ssh/id_rsa
            
        2.3.3 Remove the part of the authorized_kesy file that avoid login as root (every thing until `ssh-rsa`)
            sudo nano cat /root/.ssh/authorized_keys 

        2.3.3 Add permission to login as root using SSH, for this uncomment and change to have `PermitRootLogin yes` and `PasswordAuthentication no` in /etc/ssh/sshd_config (can be find in the Authentication section of the file)
            sudo nano /etc/ssh/sshd_config

        2.3.4 Set root password explicitly (password to use: `Jonas1!`)
            sudo passwd root 
            Jonas1! [Press Enter]
            Jonas1! [Press Enter]

        2.3.5 Reboot the VM
            sudo reboot
    
    2.4 Push the Gitlab SSH key to the other VMs by running following commands
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@10.0.2.11
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@10.0.2.12
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@10.0.2.13



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

