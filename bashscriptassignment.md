Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"

  # Master node
  config.vm.define "master" do |master|
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end

    # Use a unique host port for SSH forwarding on the master machine
    master.vm.network :forwarded_port, guest: 22, host: 2222
  end

  # Slave node
  config.vm.define "slave" do |slave|
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end

    # Use another unique host port for SSH forwarding on the slave machine
    slave.vm.network :forwarded_port, guest: 22, host: 2223
  end
end




#!/bin/bash

# Provision master
vagrant up

# Provision slave

# Create user 'altschool' and grant root privileges on master
vagrant ssh master -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh master -c "sudo usermod -aG sudo altschool"
vagrant ssh master -c "echo 'altschool:your_password' | sudo chpasswd"


# Install LAMP stack on master
vagrant ssh master -c "sudo apt-get update"
vagrant ssh master -c "sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Secure MySQL installation on master
vagrant ssh master -c  "echo -e 'y\nyour_password\nyour_password\ny\ny\ny\n\ny' | sudo mysql_secure_installation && echo 'exit' | sudo mysql"


# Ensure Apache is running and set to start on boot on master
vagrant ssh master -c "sudo systemctl enable apache2"
vagrant ssh master -c "sudo systemctl start apache2"

#!/bin/bash

# ... (previous script content)

# Validate PHP functionality with Apache on master
vagrant ssh master -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"

# Validate PHP functionality with Apache on slave
vagrant ssh slave -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"

# ... (remaining script content)


# Generate SSH key pair for 'altschool' on master
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa -b 4096 -N '' -f /home/altschool/.ssh/id_rsa"
vagrant ssh master -c "sudo -u altschool ssh-keyscan -H slave >> /home/altschool/.ssh/known_hosts"
vagrant ssh master -c "sudo -u altschool ssh-copy-id altschool@slave"

# Install LAMP stack on slave
vagrant ssh slave -c "sudo apt-get update"
vagrant ssh slave -c "sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Secure MySQL installation on slave
vagrant ssh slave -c "echo -e 'y\nMynewPassword2\nMynewPassword2\ny\ny\ny\n\ny' | sudo mysql_secure_installation && echo 'exit' | sudo mysql"

# Ensure Apache is running and set to start on boot on slave
vagrant ssh slave -c "sudo systemctl enable apache2"
vagrant ssh slave -c "sudo systemctl start apache2"

# Copy contents from master to slave
vagrant ssh master -c "sudo -u altschool cp -r /mnt/altschool/. /tmp/altschool"
vagrant ssh master -c "sudo -u altschool scp -o StrictHostKeyChecking=no -r /tmp/altschool altschool@slave:/mnt/altschool/"
vagrant ssh master -c "rm -r /tmp/altschool"







#!/bin/bash

# Script to set up passwordless SSH from master to slave

# Generate SSH key pair on master
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa -b 4096 -N '' -f /home/altschool/.ssh/id_rsa"

# Create altschool user on slave
vagrant ssh slave -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh slave -c "sudo mkdir -p /home/altschool/.ssh && sudo touch /home/altschool/.ssh/authorized_keys"

# Copy public key from master to slave
vagrant ssh master -c "sudo -u altschool cat /home/altschool/.ssh/id_rsa.pub" | vagrant ssh slave -c "sudo -u altschool sh -c 'cat >> /home/altschool/.ssh/authorized_keys'"

# Set proper permissions on master
vagrant ssh master -c "sudo chown -R altschool:altschool /home/altschool/.ssh && sudo chmod 700 /home/altschool/.ssh && sudo chmod 600 /home/altschool/.ssh/id_rsa"

# Set proper permissions on slave
vagrant ssh slave -c "sudo chown -R altschool:altschool /home/altschool/.ssh && sudo chmod 700 /home/altschool/.ssh && sudo chmod 600 /home/altschool/.ssh/authorized_keys"

# Test SSH connection from master to slave
vagrant ssh master -c "sudo -u altschool ssh altschool@slave"

