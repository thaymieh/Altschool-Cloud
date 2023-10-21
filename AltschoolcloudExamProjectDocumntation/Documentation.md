## pre-requisites

user - altschool
password - mynewpassword
host names - master and slave
master ip - 192.168.27.15
slave ip - 192.168.27.20


## Create vagrantfile

```bash

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"

  # Master node
  config.vm.define "master" do |master|
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    master.vm.network "private_network", ip: "192.168.27.15"
    # Use a unique host port for SSH forwarding on the master machine
    master.vm.network :forwarded_port, guest: 22, host: 2222 
  end

  # Slave node
  config.vm.define "slave" do |slave|
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    slave.vm.network "private_network", ip: "192.168.27.20"
    # Use another unique host port for SSH forwarding on the slave machine
    slave.vm.network :forwarded_port, guest: 22, host: 2223
  end
end
 ```

## spin up the servers

```bash
  vagrant up
```

## create altschool user on both master node and slave node to make changes without affecting root or vagrant user

```bash
  # User setup on master
vagrant ssh master -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh master -c "sudo usermod -aG sudo altschool"
vagrant ssh master -c "echo 'altschool:mynewpassword' | sudo chpasswd"

# User setup on slave
vagrant ssh slave -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh slave -c "sudo usermod -aG sudo altschool"
vagrant ssh slave -c "echo 'altschool:mynewpassword' | sudo chpasswd"
```

## create passwordless ssh: master to ssh to slave and vice versa,becasue there will be file sharing happening

```bash
# SSH key setup between master and slave
# Generate SSH key on master
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa"

# Update /etc/hosts on master to include slave
vagrant ssh master -c "echo '192.168.27.20 slave' | sudo tee -a /etc/hosts"

# Copy public key from master to slave
vagrant ssh master -c "sudo -u altschool ssh-copy-id altschool@192.168.27.20"

# Set proper permissions on master
vagrant ssh master -c "sudo chown -R altschool:altschool /home/altschool/.ssh && sudo chmod 700 /home/altschool/.ssh && sudo chmod 600 /home/altschool/.ssh/id_rsa"

# Generate SSH key on slave
vagrant ssh slave -c "sudo -u altschool ssh-keygen -t rsa"

# Update /etc/hosts on slave to include master
vagrant ssh slave -c "echo '192.168.27.15 master' | sudo tee -a /etc/hosts"

# Copy public key from slave to master
vagrant ssh slave -c "sudo -u altschool ssh-copy-id altschool@192.168.27.15"

# Set proper permissions on slave
vagrant ssh slave -c "sudo chown -R altschool:altschool /home/altschool/.ssh && sudo chmod 700 /home/altschool/.ssh && sudo chmod 600 /home/altschool/.ssh/id_rsa"

```

## Screenshot 1

![Alt text](AltschoolcloudExamProjectDocumntation/images/exam2.png)

## create directory

```bash
# Directory setup on both nodes
vagrant ssh master -c 'sudo -u altschool mkdir -p /home/altschool/scripts /home/altschool/logs'
vagrant ssh slave -c 'sudo -u altschool mkdir -p /home/altschool/scripts /home/altschool/logs'
```

## append shebang

```bash
# Enter the master node and create the deployment script
vagrant ssh master
sudo su altschool
cd ..
cd altschool/scripts/
echo '#!/bin/bash' > deploylamp.sh
```


## write the deploy lamp stack into a file called deploylamp.sh

```bash

# Deploy LAMP stack script
deploy_script_content="

# Update package information
sudo apt-get update

# Upgrade installed packages
sudo apt-get upgrade -y

# Install LAMP stack components
sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql git

# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Start and enable MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Clone Laravel repository
git clone https://github.com/laravel/laravel /var/www/html/laravel

# Create MySQL database
sudo mysql -e \"CREATE DATABASE altschool_db;\"
sudo mysql -e \"CREATE USER 'altschool'@'localhost' IDENTIFIED BY 'Altschool.cloud';\"
sudo mysql -e \"GRANT ALL PRIVILEGES ON altschool_db.* TO 'altschool'@'localhost';\"
sudo mysql -e \"FLUSH PRIVILEGES;\"

# Configure Apache for Laravel
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/laravel.conf
sudo sed -i 's|/var/www/html|/var/www/html/laravel/public|g' /etc/apache2/sites-available/laravel.conf
sudo a2ensite laravel.conf
sudo systemctl restart apache2

# Set ServerName in Apache configuration
sudo bash -c 'echo \"ServerName localhost\" >> /etc/apache2/apache2.conf'

# Restart Apache
sudo service apache2 restart

# Display deployment completion message
echo \"LAMP stack deployed successfully.\"
"

# Append deploy script content to deploylamp.sh
vagrant ssh master -c 'sudo -u altschool tee -a /home/altschool/scripts/deploylamp.sh' <<< "$deploy_script_content"

```

## copy deploylamp.sh to slave node

```bash
# Copy deploylamp.sh to the slave node
vagrant ssh master -c "sudo -u altschool scp -o StrictHostKeyChecking=no /home/altschool/scripts/deploylamp.sh altschool@slave:/home/altschool/scripts/"

```

## install ansible on slave node
```bash
# Install Ansible on the slave node
vagrant ssh slave -c "sudo -u altschool sudo apt-get update && sudo apt-get install ansible -y"
```

## creating ansible inventory.ini
```bash
# Ansible inventory setup
inventory_content="
# inventory.ini
[master]
master ansible_ssh_host=192.168.27.15 ansible_ssh_user=altschool

[slave]
slave ansible_ssh_host=192.168.27.20 ansible_ssh_user=altschool

[all:vars]
ansible_python_interpreter=/usr/bin/python3
"
# Append inventory content to inventory.ini on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/inventory.ini' <<< "$inventory_content"
```

## creating ansible deploy.yml to deploy lamp stack on master node

```bash
# Ansible playbook setup for deployment
ansible_playbook_content="
# deploy_on_master.yml
---
- name: Deploy LAMP stack on Master and verify PHP application
  hosts: slave
  become: yes

  tasks:
    - name: Upload and execute the Bash script on Master
      script: /home/altschool/scripts/deploylamp.sh
      delegate_to: master
      register: script_result

    - name: Display script result on Master
      debug:
        var: script_result.stdout_lines
      when: script_result is defined and script_result.stdout_lines | length > 0

    - name: Display script error on Master
      debug:
        var: script_result.stderr_lines
      when: script_result is defined and script_result.stderr_lines | length > 0

    - name: Verify PHP application on Master
      uri:
        url: "http://master/laravel"
        status_code: 200
      register: result

    - name: Display verification result on Master
      debug:
        var: result
"

# Append Ansible playbook content to deploy.yml on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/deploy.yml' <<< "$ansible_playbook_content"
```

## creating cronjob to check server uptime
```bash
# Ansible playbook setup for cron job
cronjob_content="
# deploy_cronjob.yml
---
- name: Create Cron Job to Check Server Uptime
  hosts: slave
  become: true
  become_user: altschool

  tasks:
    - name: Create Cron Job to Check Server Uptime
      cron:
        name: 'Check_Server_Uptime'
        job: 'uptime >> /home/altschool/logs/uptime.log'
        minute: 0
        hour: 0
        state: present
      delegate_to: master
"

# Append Ansible cronjob content to cronjob.yml on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/cronjob.yml' <<< "$cronjob_content"
```

## Execution of ansible playbook

```bash

# Run Ansible playbook for deployment
vagrant ssh slave -c "sudo -u altschool ansible-playbook -i /home/altschool/scripts/inventory.ini /home/altschool/scripts/deploy.yml --ask-become-pass"

# Run Ansible playbook for cron job
vagrant ssh slave -c "sudo -u altschool ansible-playbook -i /home/altschool/scripts/inventory.ini /home/altschool/scripts/cronjob.yml --ask-become-pass"

```
## Screenshot 2

![Alt text](AltschoolcloudExamProjectDocumntation/images/exam3.png)

## Screenshot 3

![Alt text](AltschoolcloudExamProjectDocumntation/images/exam4.png)

## Screenshot 4

![Alt text](AltschoolcloudExamProjectDocumntation/images/exam5.png)

## Screenshot 5

![Alt text](AltschoolcloudExamProjectDocumntation/exam2.png)



