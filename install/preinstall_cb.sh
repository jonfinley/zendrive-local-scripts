#!/bin/bash
#
# This script will setup all the initial steps before you run the plexstandard.

### cb remove
cbremove() {
    echo 'Remove CloudBox'
    containers=$(comm -12 <(docker ps -a -q | sort) <(docker ps -q | sort))
    for container in $containers;
    do
        echo "Stopping $container"
        docker stop "$container"
        docker rm "$container"
    done
}

### cb cleanup
cbcleanup() {
    echo 'Clean Up CloudBox'
    rm -rf /home/seed/cloudbox
}

### shell setup
shellsetup() {
    echo 'Shell Setup'
    ##Shell Setup
    sudo apt install -y apache2-utils bwm-ng cifs-utils git htop intel-gpu-tools iotop iperf3 ncdu nethogs nload psmisc python3-pip python-pip screen sqlite3 tmux tree unrar-free vnstat wget zsh
    sudo apt remove mlocate -y
    ## Kernel Things
    wget -O /usr/local/bin/ https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
    chmod +x /usr/local/bin/ubuntu-mainline-kernel.sh
    sudo /usr/local/bin/ubuntu-mainline-kernel.sh -i
}

### folder setup
foldersetup() {
    echo 'Folder Setup'
    sudo mkdir /mnt/{local,sharedrives,unionfs}
    sudo mkdir /opt/{logs,plex_db_backups,traefik,docker}
    sudo mkdir /opt/scripts/installers
}
### repo setup
reposetup() {
    echo 'Repo Setup'
    git clone https://github.com/zenjabba/zendrive-local-scripts/ /opt/scripts/zendrive
    git clone https://github.com/blacktwin/JBOPS /opt/scripts/JBOPS
    curl https://rclone.org/install.sh | sudo bash -s beta
    wget https://github.com/trapexit/mergerfs/releases/download/2.30.0/mergerfs_2.30.0.ubuntu-bionic_amd64.deb -P /opt/scripts/installers
    sudo dpkg -i /opt/scripts/installers/mergerfs_2.30.0.ubuntu-bionic_amd64.deb
    sudo sed -i 's|http://nl.|http://|g' /etc/apt/sources.list
}

### user setup
usersetup() {
    echo 'User Setup'
    sudo useradd -m seed
    sudo usermod -aG sudo seed
    password=$(date +%s | sha256sum | base64 | head -c 12)
    echo -e "$password\n$passwd" | passwd seed
    #sudo chown seed:seed /opt/{plex,scripts,logs,plex_db_backups,traefik,docker}
}

### docker setup
dockersetup() {
    echo 'Docker Setup'
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io -y
    sudo usermod -aG docker seed
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    sudo apt-get upgrade -y 

### systemd override for docker to wait for mergerfs
cat > /etc/systemd/system/docker.service.d/override.conf << "_EOF_"
[Unit]
After=
After=mergerfs.service
[Service]
ExecStartPre=
ExecStartPre=/bin/sleep 15
_EOF_
}

### message
message() {
    echo "This script is in process."
    echo ""
    echo "seed password is $password"
    echo " "
    echo "  1. Create config file using the sample."
    echo "       a. cp sample_config config.conf"
    echo "    How to find your keys:"
    echo "        Head over to https://dashboard.zenjabba.com/ and you will find your access and secret keys listed in your services"
    echo "        They will look somthing like:"
    echo "        AABBCCDDEEFFGGHH IIJJKKLLMMNNOOPPQQRRSSTT "
    echo "  2. Run install script when complete"
    echo "        sudo bash /opt/scripts/zendrive/install/install.sh to complete installation"
    echo ""
    echo "enjoy :)"
    touch /opt/scripts/zendrive/.preinstall
}

main() {
    cbremove
    cbcleanup
    shellsetup
    foldersetup
    usersetup
    reposetup
    dockersetup
    message
}