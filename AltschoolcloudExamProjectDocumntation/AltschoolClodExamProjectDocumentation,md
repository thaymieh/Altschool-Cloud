
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"

  # Master node
  config.vm.define "master" do |master|
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    master.vm.network "private_network", ip: "192.168.27.15"
    master.vm.network :forwarded_port, guest: 22, host: 2222 
  end

  # Slave node
  config.vm.define "slave" do |slave|
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    slave.vm.network "private_network", ip: "192.168.27.20"
    slave.vm.network :forwarded_port, guest: 22, host: 2223
  end
end

# Provisioning Script
#!/bin/bash

# User setup on master
vagrant ssh master -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh master -c "sudo usermod -aG sudo altschool"
vagrant ssh master -c "echo 'altschool:mynewpassword' | sudo chpasswd"

# User setup on slave
vagrant ssh slave -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh slave -c "sudo usermod -aG sudo altschool"
vagrant ssh slave -c "echo 'altschool:mynewpassword' | sudo chpasswd"

# SSH key setup
vagrant ssh master -c "ssh-keygen -t rsa -b 4096"
vagrant ssh master -c "echo '192.168.27.20 slave' | sudo tee -a /etc/hosts"
vagrant ssh master -c "ssh-copy-id altschool@192.168.27.20"

vagrant ssh slave -c "ssh-keygen -t rsa -b 4096"
vagrant ssh slave -c "echo '192.168.27.15 master' | sudo tee -a /etc/hosts"
vagrant ssh slave -c "ssh-copy-id altschool@192.168.27.15"

# Directory setup
vagrant ssh master -c 'sudo -u altschool mkdir -p /home/altschool/scripts /home/altschool/logs'
vagrant ssh slave -c 'sudo -u altschool mkdir -p /home/altschool/scripts'

# Copy script from master to slave
vagrant ssh master -c "sudo -u altschool scp -o StrictHostKeyChecking=no /home/altschool/scripts/deploylamp.sh altschool@slave:/home/altschool/scripts/"

# Ansible installation on the slave
vagrant ssh slave -c "sudo apt-get update && sudo apt-get install ansible -y"

# Deploy LAMP stack script
deploy_script_content="
#!/bin/bash
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

# Ansible playbook setup
ansible_playbook_content="
# deploy_on_master.yml
---
- name: Deploy LAMP stack on Master and verify PHP application
  hosts: slaves
  become: yes

  tasks:
    - name: Upload and execute the Bash script on Master
      script: /home/altschool/scripts/deploylamp.sh
      delegate_to: "{{ groups['masters'][0] }}"
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
        url: "http://{{ groups['masters'][0] }}/laravel"
        status_code: 200
      register: result

    - name: Display verification result on Master
      debug:
        var: result
"

# Append Ansible playbook content to deploy.yml on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/deploy.yml' <<< "$ansible_playbook_content"

# Cronjob setup
inventory_content="
# inventory.ini
[masters]
master ansible_ssh_host=192.168.27.15 ansible_ssh_user=altschool

[slaves]
slave ansible_ssh_host=192.168.27.20 ansible_ssh_user=altschool

[all:vars]
ansible_python_interpreter=/usr/bin/python3
"

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
        name: "Check_Server_Uptime"
        job: "uptime >> /home/altschool/logs/uptime.log"
        minute: 0
        hour: 0
        state: present
      delegate_to: "{{ groups['master'][0] }}"
"

# Append inventory content to inventory.ini on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/inventory.ini' <<< "$inventory_content"

# Append Ansible cronjob content to cronjob.yml on the slave node
vagrant ssh slave -c 'sudo -u altschool tee -a /home/altschool/scripts/cronjob.yml' <<< "$cronjob_content"

# Ansible playbook and cronjob execution
vagrant ssh slave -c "ansible-playbook -i /home/altschool/scripts/inventory.ini /home/altschool/scripts/deploy.yml --ask-become-pass"
vagrant ssh slave -c "ansible-playbook -i /home/altschool/scripts/inventory.ini /home/altschool/scripts/cronjob.yml --ask-become-pass"
