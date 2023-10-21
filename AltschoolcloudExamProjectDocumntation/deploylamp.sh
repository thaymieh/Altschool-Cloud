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
sudo mysql -e "CREATE DATABASE altschool_db;"
sudo mysql -e "CREATE USER 'altschool'@'localhost' IDENTIFIED BY 'Altschool.cloud';"
sudo mysql -e "GRANT ALL PRIVILEGES ON altschool_db.* TO 'altschool'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configure Apache for Laravel
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/laravel.conf
sudo sed -i 's|/var/www/html|/var/www/html/laravel/public|g' /etc/apache2/sites-available/laravel.conf
sudo a2ensite laravel.conf
sudo systemctl restart apache2

# Set ServerName in Apache configuration
sudo bash -c 'echo "ServerName localhost" >> /etc/apache2/apache2.conf'

# Restart Apache
sudo service apache2 restart

# Display deployment completion message
echo "LAMP stack deployed successfully."

