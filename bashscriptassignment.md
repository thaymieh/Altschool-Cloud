#!/bin/bash
# cd to the vagrant folder 
# Task 1: Infrastructure Configuration
vagrant up

# Task 2: User Management
vagrant ssh master -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh master -c "sudo usermod -aG sudo altschool"
vagrant ssh master -c "echo 'altschool:mynewpassword' | sudo chpasswd"

# Task 3: Inter-node Communication
# Create altschool user on slave
vagrant ssh slave -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh slave -c "sudo usermod -aG sudo altschool"
vagrant ssh slave -c "echo 'altschool:your_password' | sudo chpasswd"

# Generate SSH key pair on master
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa"
vagrant ssh master -c "echo '10.0.2.15 slave' | sudo tee -a /etc/hosts"
vagrant ssh master -c "sudo -u altschool ssh-copy-id altschool@10.0.2.15"
vagrant ssh master -c "sudo -u altschool cat /home/altschool/.ssh/id_rsa.pub" | vagrant ssh slave -c "sudo -u altschool sh -c 'cat >> /home/altschool/.ssh/authorized_keys'"
vagrant ssh master -c "sudo chown -R altschool:altschool /home/altschool/.ssh && sudo chmod 700 /home/altschool/.ssh && sudo chmod 600 /home/altschool/.ssh/id_rsa"
vagrant ssh master -c "sudo -u altschool ssh altschool@slave"

# Task 4: Data Management and Transfer
# Copy contents from master to slave
vagrant ssh master -c "sudo mkdir -p /mnt/altschool && sudo chown altschool:altschool /mnt/altschool"
vagrant ssh master -c "echo 'Hello, welcome to altschool cloud.' | sudo tee /mnt/altschool/welcome.txt"
vagrant ssh slave -c "sudo mkdir -p /mnt/altschool && sudo chown altschool:altschool /mnt/altschool"
vagrant ssh master -c "sudo -u altschool scp -o StrictHostKeyChecking=no /mnt/altschool/welcome.txt altschool@slave:/mnt/altschool/"

# Task 5: Process Monitoring
vagrant ssh master -c "htop"

# Task 6: LAMP Stack Deployment (On Master)
vagrant ssh master -c "sudo apt update"
vagrant ssh master -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"
vagrant ssh master -c "sudo service apache2 start"
vagrant ssh master -c "sudo service mysql start"
vagrant ssh master -c "sudo systemctl enable apache2"
vagrant ssh master -c "sudo systemctl enable mysql"
vagrant ssh master -c "sudo mysql_secure_installation <<EOF
y
~yVG#uh8ZSgdGZm
~yVG#uh8ZSgdGZm
y
y
y
y
EOF"
vagrant ssh master -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"
master_ip=$(vagrant ssh master -c "ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1")
vagrant ssh master -c "sudo bash -c 'echo \"ServerName localhost\" >> /etc/apache2/apache2.conf'"
vagrant ssh master -c "sudo service apache2 restart"
vagrant ssh master -c "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d '/' -f 1"

# Task 6: LAMP Stack Deployment (On Slave)
vagrant ssh slave -c "sudo apt update"
vagrant ssh slave -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"
vagrant ssh slave -c "sudo service apache2 start"
vagrant ssh slave -c "sudo service mysql start"
vagrant ssh slave -c "sudo systemctl enable apache2"
vagrant ssh slave -c "sudo systemctl enable mysql"
vagrant ssh slave -c "sudo mysql_secure_installation <<EOF
y
~yVG#uh8ZSgdGZm
~yVG#uh8ZSgdGZm
y
y
y
y
EOF"
vagrant ssh slave -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"
slave_ip=$(vagrant ssh slave -c "ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1")
vagrant ssh slave -c "sudo bash -
