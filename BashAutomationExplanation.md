## Task 1

Infrastructure Configuration:
Deploy two Ubuntu systems:
Master Node: This node should be capable of acting as a control system.
Slave Node: This node will be managed by the Master node.


```bash
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
```
above is the vagrant file configuration


```bash
  vagrant up
```


## Task 2

User Management:
On the Master node:
Create a user named altschool.
Grant altschool user root (superuser) privileges.

```bash
vagrant ssh master -c "sudo useradd -m -s /bin/bash altschool"
vagrant ssh master -c "sudo usermod -aG sudo altschool"
vagrant ssh master -c "echo 'altschool:your_password' | sudo chpasswd"
```

## Task 3

Inter-node Communication:
Enable SSH key-based authentication:
The Master node (altschool user) should seamlessly SSH into the Slave node without requiring a password.

```bash
vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa -b 4096 -N '' -f /home/altschool/.ssh/id_rsa"
vagrant ssh master -c "sudo -u altschool ssh-copy-id -i /home/altschool/.ssh/id_rsa altschool@slave"
vagrant ssh master -c "sudo -u altschool ssh altschool@slave"
vagrant ssh master -c "sudo -u altschool ls -la /home/altschool/.ssh/"
```



## Task 4

Data Management and Transfer:
On initiation:
Copy the contents of /mnt/altschool directory from the Master node to /mnt/altschool/slave on the Slave node. This operation should be performed using the altschool user from the Master node.

```bash
  vagrant ssh master -c "sudo -u altschool ssh-keygen -t rsa -b 4096 -N '' -f /home/altschool/.ssh/id_rsa"
vagrant ssh master -c "sudo -u altschool ssh-keyscan -H slave >> /home/altschool/.ssh/known_hosts"
vagrant ssh master -c "sudo -u altschool ssh-copy-id altschool@slave"
```

## Task 5

Process Monitoring:
The Master node should display an overview of the Linux process management, showcasing currently running processes.

```bash
  sudo useradd -m alade
```

## Task 6

LAMP Stack Deployment:
Install a LAMP (Linux, Apache, MySQL, PHP) stack on both nodes:
Ensure Apache is running and set to start on boot.
Secure the MySQL installation and initialize it with a default user and password.
Validate PHP functionality with Apache.

# On Master
```bash
  # Install LAMP stack on master
vagrant ssh master -c "sudo apt-get update"
vagrant ssh master -c "sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Secure MySQL installation on master
vagrant ssh master -c  "echo -e 'y\nyour_password\nyour_password\ny\ny\ny\n\ny' | sudo mysql_secure_installation && echo 'exit' | sudo mysql"


# Ensure Apache is running and set to start on boot on master
vagrant ssh master -c "sudo systemctl enable apache2"
vagrant ssh master -c "sudo systemctl start apache2"
```

# On slave

```bash
# Install LAMP stack on slave
vagrant ssh slave -c "sudo apt-get update"
vagrant ssh slave -c "sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Secure MySQL installation on slave
vagrant ssh slave -c "echo -e 'y\nMynewPassword2\nMynewPassword2\ny\ny\ny\n\ny' | sudo mysql_secure_installation && echo 'exit' | sudo mysql"

# Ensure Apache is running and set to start on boot on slave
vagrant ssh slave -c "sudo systemctl enable apache2"
vagrant ssh slave -c "sudo systemctl start apache2"
```






















