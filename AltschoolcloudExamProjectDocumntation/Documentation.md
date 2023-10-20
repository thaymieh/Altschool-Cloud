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
 ````

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

````bash
# Generate SSH key pair on master
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa"

# Add slave's IP to master's /etc/hosts
vagrant ssh master -c "echo '192.168.27.20 slave' | sudo tee -a /etc/hosts"

# Copy public key from master to slave
public_key=$(vagrant ssh master -c "sudo -u altschool cat /home/altschool/.ssh/id_rsa.pub")
vagrant ssh slave -c "sudo -u altschool sh -c 'echo \"$public_key\" >> /home/altschool/.ssh/authorized_keys'"

# Set proper permissions on master's SSH directory
vagrant ssh master -c "sudo chown -R altschool:altschool /home/altschool/.ssh && \
                      sudo chmod 700 /home/altschool/.ssh && \
                      sudo chmod 600 /home/altschool/.ssh/id_rsa"

# Test SSH connection from master to slave
vagrant ssh master -c "sudo -u altschool ssh altschool@192.168.27.20"

exit


# Generate SSH key pair on slave
vagrant ssh slave -c "sudo -u altschool ssh-keygen -t rsa"

# Add slave's IP to master's /etc/hosts
vagrant ssh slave -c "echo '192.168.27.15 master' | sudo tee -a /etc/hosts"

# Copy public key from master to slave
public_key=$(vagrant ssh slave -c "sudo -u altschool cat /home/altschool/.ssh/id_rsa.pub")
vagrant ssh master -c "sudo -u altschool sh -c 'echo \"$public_key\" >> /home/altschool/.ssh/authorized_keys'"

# Set proper permissions on master's SSH directory
vagrant ssh slave -c "sudo chown -R altschool:altschool /home/altschool/.ssh && \
                      sudo chmod 700 /home/altschool/.ssh && \
                      sudo chmod 600 /home/altschool/.ssh/id_rsa"

# Test SSH connection from master to slave
vagrant ssh slave -c "sudo -u altschool ssh altschool@192.168.27.15"


exit
```

## create directory

```bash
# Directory setup
vagrant ssh master -c 'sudo -u altschool mkdir -p /home/altschool/scripts /home/altschool/logs'
vagrant ssh slave -c 'sudo -u altschool mkdir -p /home/altschool/scripts /home/altschool/logs'
```

## write the deloy lamp stack into a file called deploylamp.sh

```bash
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
```
