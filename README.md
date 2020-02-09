# T-NSA

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
            sudo nano /root/.ssh/authorized_keys

        2.3.3 Add permission to login as root using SSH, for this uncomment and change to have `PermitRootLogin yes` and `PasswordAuthentication yes` in /etc/ssh/sshd_config (can be find in the Authentication section of the file)
            sudo nano /etc/ssh/sshd_config

        2.3.4 Set root password explicitly (password to use: `Jonas1!`)
            sudo passwd root
            Jonas1! [Press Enter]
            Jonas1! [Press Enter]

        2.3.5 Reboot the VM
            sudo reboot

    2.4 Push the Gitlab SSH key to the other VMs by running following commands
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub root@10.0.2.11
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub root@10.0.2.12
        sudo ssh-copy-id -i /home/jonas/.ssh/id_rsa.pub root@10.0.2.13



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

    2.4 Create script that starts gitlab runner
        nano ~/startGitlabRunner.sh

        With the following content:
        docker run -d --name gitlab-runner --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab gitlab-runner:latest

    2.5 Start Gitlab runner
        sudo chmod +x ./startGitlabRunner.sh
        sudo sh startGitlabRunner.sh

    2.6 Install ansible
        sudo apt-add-repository ppa:ansible/ansible
        sudo apt-get update --fix-missing
        sudo apt-get install ansible -y

    2.7 Clone this repository

    2.8 Copy the content of the `setup/ansible` directory of this repo into /etc
        sudo cp -r t-nsa/setup/ansible /etc

    2.9 Setup the VMs
        sudo ansible-playbook /etc/ansible/install_and_setup_db.yml
        sudo ansible-playbook /etc/ansible/install_and_setup_front.yml
        sudo ansible-playbook /etc/ansible/install_and_setup_back.yml


If you need to restart the gitlab server, run following commands:
sudo docker container ls -a
sudo docker container stop <container_id>
sudo docker container rm <container_id>
sudo sh ./startGitlab.sh


To test if the mysql server is listening, run following command on db VM:
sudo netstat -tulnp | grep mysql
```
