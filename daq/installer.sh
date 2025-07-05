#!/bin/bash

sudo dnf config-manager --set-enabled crb

###############
# AUTOMATIC OPERATIONS

# 0)
sudo dnf update -y

# 4)
sudo dnf install gcc -y

# 5)
sudo dnf install gnuplot -y

# 6)
sudo dnf install epel-release -y

# 7)
sudo dnf install fuse-sshfs -y

# 8)
sudo dnf install python3 -y

# 9)
sudo dnf install kernel-devel kernel-headers -y
sudo dnf install kernel-devel-matched
sudo dnf install kernel-devel kernel-headers -y

# 11)
sudo dnf install automake -y

# 12)
sudo dnf install memcached -y
sudo dnf install libmemcached -y
sudo dnf install libmemcached-devel -y

# O-2)
sudo dnf install tmux -y

# O-4)
sudo dnf install x11vnc -y

###############
# MANUAL OPERATIONS

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "final mandatory components, to be installed in the following order:"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# 1)
echo "[1] manually install CAENVMELim Library"
echo "--> https.caen.it/products/caenvmelib-library/"
echo "--> cd lib ; sudo sh install_x64"

# 2)
echo "[2] manually install CAENComm Library"
echo "--> https://www.caen.it/products/caencomm-library/"
echo "--> cd lib ; sudo sh install_x64"

# 3)
echo "[3] manually install CAENDigitizer Library"
echo "--> https://www.caen.it/products/caendigitizer-library/"
echo "--> cd lib ; sudo sh install_x64"

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "final optional components, to be installed in the following order:"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# O-0)
echo "[O-0] manually install CAENUpgrader"
echo "--> https://www.caen.it/products/caenupgrader/"
echo "--> ./configure ; make ; sudo make install"

# O-1)
echo "[O-1] manually install CAEN Toolbox"
echo "--> https://www.caen.it/products/caen-toolbox/"
echo "--> chmod +x install.sh ; sudo ./install.sh"

# 10)
echo "[10] manually install required digitiser USB drivers, e.g."
echo "USB Driver DT57xx N67xx DT55xx V1718 V3718 N957 Linux"
echo "--> https://www.caen.it/download/?filter=DT5720"
echo "--> make ; sudo make install"

# O-3)
echo "[O-3] manually install required controller drivers, e.g."
echo "A3818 Driver for Linux"
echo "--> https://www.caen.it/products/a3818/"
echo "--> make ; sudo make install"

# O-5)
echo "" >> $HOME/.bashrc
echo "# proper shortcut for VNC server:" >> $HOME/.bashrc
echo 'alias x11vnc="x11vnc -usepw -reopen -forever -rbfport 5901"' >> $HOME/.bashrc 
echo "[O-5] manually setup VNC server and firewall:"
echo "--> vncpasswd"
echo "--> disable firewall (e.g. systemctl status/stop/disable firewalld)"
echo "--> proper shortcut (x11vnc) already defined in .bashrc"
echo "--> note: to make this work, choose an X11-based desktop environment (typically at password login)"

echo "~~~~~~~~~~~~~~~~~~~~~"
echo "set up and operation:"
echo "~~~~~~~~~~~~~~~~~~~~~"

# final) 
echo "[FINAL] enter the main directory, compile & run:"
echo "--> cd wavedump-3.10.6-MOD ; autoreconf -f -i ; make clean ; make ; sudo make install ; cd .."
echo "--> source setup.sh, then follow from there"

# notes
echo "[OTHER NOTE] if make fails due to kernel versioning errors (aka kernel panic)"
echo "--> try rerunning: sudo dnf install kernel-devel kernel-headers -y"
echo '--> could try also: sudo dnf install "kernel-devel-$(uname -r)" -y'
echo "--> then reboot"
echo "[OTHER NOTE] for desktop environment selection from login on certain OSs, it is best to"
echo "--> have a user with password (sudo passwd [USERNAME] if not already set)"
echo "--> have automatic login disabled"
echo "--> these settings will force the login screen to have a desktop environment selection menu"
echo "--> then make the user a sudoer to simplify operations"
