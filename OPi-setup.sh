#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

sudo apt -y remove unattended-upgrades
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade

sudo apt install -y xfce4-goodies indicator-multiload

# Installs Synaptic Package Manager for easy software install/removal
echo "Installing Synaptic and apt-add-repository"
sudo apt -y install synaptic software-properties-common


#########################################################
#############  File Sharing Configuration

echo "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt -y install samba samba-common-bin

if [ ! -f /etc/samba/smb.conf ]
then
	sudo mkdir -p /etc/samba/
##################
sudo --preserve-env bash -c 'cat > /etc/samba/smb.conf' <<- EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   obey pam restrictions = yes
   unix password sync = yes
   log file = /var/log/samba/log.%m
   max log size = 50
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes
[opi]
   comment = opi Home
   path = /home/opi
   browseable = yes
   writeable = yes
   read only = no
   valid users = opi
EOF
##################
fi

# Adds yourself to the user group of who can use samba, but checks first if you are already in the list
if [ -z "$(sudo pdbedit -L | grep $SUDO_USER)" ]
then
	sudo smbpasswd -a orangepi
	sudo adduser orangepi sambashare
fi


#########################################################
#############  Install and setup x11VNC


sudo apt install lightdm

#Select lightdm as your default display manager in the configuration window.
#Need to install vnc compatible display manager; gnome doesn't work with x11vnc server.
#sudo reboot; rebot the system for the display manger to take affect

sudo apt -y install x11vnc

x11vnc -storepasswd /etc/x11vnc.pass

# This will create the service file.

######################
sudo --preserve-env bash -c 'cat > /lib/systemd/system/x11vnc.service' << EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
[Install]
WantedBy=multi-user.target
EOF
######################

# This enables the Service so it runs at startup
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service
sudo systemctl daemon-reload

sudo usermod -a -G dialout opi

#########################################################
#############  ASTRONOMY SOFTWARE

# Installs INDI, Kstars, and Ekos bleeding edge and debugging
echo "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt update
sudo apt -y install indi-full kstars-bleeding


# Creates a config file for kde themes and icons which is missing on the Raspberry pi.
# Note:  This is required for KStars to have the breeze icons.
echo "Creating KDE config file so KStars can have breeze icons."
##################
sudo --preserve-env bash -c 'cat > $USERHOME/.config/kdeglobals' <<- EOF
[Icons]
Theme=breeze
EOF
##################

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
echo "Installing GSC"
sudo apt -y install gsc

#########################################################
#############  INDI WEB MANAGER App

echo "Installing INDI Web Manager App, indiweb, and python3"

sudo apt -y install python3-pip
sudo apt -y install python3-dev

# Setuptools may be needed in order to install indiweb on some systems
sudo apt -y install python3-setuptools
sudo -H -u opi pip3 install setuptools --upgrade

# Wheel might not be installed on some systems
sudo -H -u $SUDO_USER pip3 install wheel

# This will install indiweb as the user
sudo -H -u $SUDO_USER pip3 install indiweb

#This will install the INDIWebManagerApp in the INDI PPA
sudo apt -y install indiwebmanagerapp

