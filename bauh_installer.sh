#!/bin/bash
#Script made by androrama fenixlinux.com
#License GPLV3. If you are a developer and this script/app helped you, I would be very grateful if you make a mention. Making free software is very difficult to make a living (ganarse la vida). I spend a lot of time doing this because it makes me happy to see how what I do helps people and to see how other developers who are probably better than me recognize my work. I think that respect between developers is fundamental and something that should be done much more. Since I am a developer I found many people who don't have respect and also criticize or try to sink other people who make free software. If we don't support each other, proprietary software will win.

#Function to check that the home directory is correct by androrama.
user=$(logname)
HOME=/home/$user
OLD_HOME="$(echo -n $(bash -c "cd ~${USER} && pwd"))"
    if [ "$HOME" != "$OLD_HOME" ]; then
       zenity --error --title="Error HOME" --text="You are running this script as root or your home directory doesn't have the same name as your user." --no-wrap
       homeAnswer=$(zenity --entry --text "Please enter the name of your home. Example: pi" --entry-text "$user"); echo New home name = $homeAnswer
       HOME=/home/$homeAnswer
    fi
#Variables    
FILE=$HOME/.local/bin/bauh 
FILEVENV=$HOME/.local/share/applications/bauh_VENV.desktop 
export PATH="$HOME/.local/bin:$PATH"
#Dpkg/apt unlock
sudo fuser -vki /var/lib/dpkg/lock
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock 2>/dev/null 
sudo rm /var/cache/apt/archives/lock 2>/dev/null 
sudo dpkg --configure -a
#Functions
uninstall () {
	bauh --reset 
	pip3 uninstall bauh
	rm ~/.local/share/applications/bauh.desktop	
	rm  ~/.local/bin/bauh
    bauh_env/bin/bauh --reset  # Clean cache and configuration files from HOME
    rm -rf $HOME/bauh_env
   	rm ~/.local/share/applications/bauh_VENV.desktop	
}
snapd () {
    REQUIRED_PKG="snapd"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
     if zenity --question --title="Install snapd" --text="Do you want to install snap packages support?"
     then
    sudo apt install snapd || echo "Unable to install snapd"
    sudo systemctl enable --now snapd.socket || echo "Unable to enable snapd.socket"
    sudo rm -rf /snap 2>/dev/null
    sudo snap install core || echo "Unable to install snap core"
    sudo ln -s /var/lib/snapd/snap /snap || echo "unable to create symbolic link between /var/lib/snapd/snap and /snap"
    sudo rm -rf /usr/share/applications/snap
    ln -s /var/lib/snapd/desktop/applications /usr/share/applications/snap || sudo ln -s /var/lib/snapd/desktop/applications /usr/share/applications/snap || "Failed to create symlink for Snap app shortcuts!"
    echo "Snapd installed."
    fi
   fi
}
flatpak () {
    REQUIRED_PKG="flatpak"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
     if zenity --question --title="Install flatpak" --text="Do you want to install flatpak packages support?"
    then
    sudo apt install flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    #https://www.raspberrypi.org/forums/viewtopic.php?t=275001
    #XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
    echo "A reboot is required."
     fi
    fi
}
alternativeapps () {
    #Gnome Software + Flatpak
    REQUIRED_PKG="gnome-software"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
    if zenity --question --width=400 --title="Install gnome-software-flatpak" --text="Do you want to install Gnome-Software as an alternative to Bauh to manage and discover Flatpak packages?"
    then
    sudo apt install flatpak
    killall gnome-software
    rm -rf ~/.cache/gnome-software
    sudo flatpak update
    sudo apt install gnome-software
    sudo apt-get --reinstall install -y gnome-software-plugin-flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    elif zenity --question --width=400 --title="Uninstall Gnome-Software" --text="Do you want to uninstall Gnome Software?"
        then
        sudo apt remove --purge gnome-software
    fi
    #Synaptic
    REQUIRED_PKG="synaptic"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
    if zenity --question --width=400 --title="Install Synaptic" --text="Do you want to install Synaptic to manage the programs?"
    then
    sudo apt install synaptic
    fi
    elif zenity --question --width=400 --title="Uninstall Synaptic" --text="Do you want to uninstall Synaptic?"
        then
        sudo apt remove --purge synaptic
    fi
    #Snap Store + Snapd
    SNAPCHECK=/usr/share/applications/snap/snap-store_snap-store.desktop
    if [ -f "$SNAPCHECK" ]; then
        if zenity --question --width=400 --title="Uninstall Snap-Store" --text="Do you want to uninstall the Snap Store?"
        then
        sudo snap remove snap-store
        fi
    elif zenity --question --width=400 --title="Install Snap-Store" --text="Do you want to install the Snap Store as an alternative to Bauh for manage and discover Snap packages?"
    then
       echo "Installing snapd, required to install and use the snap store."
       snapd
       sudo snap install snap-store    || zenity --error --title="Error" --text="Unable to install the Snap Store."
    fi
}
installonvenv () {
	cd
    pip3 install virtualenv 
    python3 -m virtualenv bauh_env      || zenity --error --title="Error" --text="Unable to install Bauh env." --no-wrap  # creates an isolated environment inside the directory called "bauh_env"
    bauh_env/bin/pip install bauh || zenity --error --title="Error" --text="Unable to install Bauh env." --no-wrap# installs bauh in the isolated environment
    bauh_env/bin/bauh             || zenity --error --title="Error" --text="Unable to install Bauh env." --no-wrap# launches bauh. For the tray-mode: bauh_env/bin/bauh-tray
    wget -qnc --continue -O ~/.local/share/icons/bauh.png https://n5b3y8j5.rocketcdn.me/wp-content/uploads/2020/11/Bauh-logo-300x215.png 
    echo "[Desktop Entry]
           Type=Application
           Name=Bauh_VENV
           GenericName=Bauh_VENV
           Comment=Graphical interface for managing your Linux software (packages/applications).
           Categories=System;
           Exec=$HOME/bauh_env/bin/bauh
           Icon=$HOME/.local/share/icons/bauh.png
           StartupWMClass=Bauh" > ~/.local/share/applications/bauh_VENV.desktop  
}
timeshift () {
    if [ `uname -m` = "x86_64" ]; then
    sudo apt install timeshift || echo "Error installing Timeshift, try doing an -apt update- before. Maybe it's not in your repositories."
    echo
    echo "Process finished. It's recommended to make a backup with Timeshift to go back if something goes wrong."
    echo 
    elif [ `getconf LONG_BIT` = "32" ]; then
    cd $DIRECTORY
    wget -qnc --continue https://github.com/teejee2008/timeshift/releases/download/v20.11.1/timeshift_20.11.1_armhf.deb -P ~/Downloads || error 'Failed to download timeshift!'
    sudo apt install -y --fix-broken ~/Downloads/timeshift_20.11.1_armhf.deb |
    zenity --progress \
    --title="Installing Timeshift" \
    --text="Installing Timeshift, as soon as the process is completed you will have a shortcut in Menu > System-Tools." \
    --percentage=0|| echo 'Failed to install .deb file!'
    rm -f timeshift_20.11.1_armhf.deb* 
    echo 
    echo
    echo "Process finished. It's recommended to make a backup with Timeshift to go back if something goes wrong."
    echo
    sleep 2
    elif [ `getconf LONG_BIT` = "64" ]; then
    wget -qnc --continue https://github.com/teejee2008/timeshift/releases/download/v20.11.1/timeshift_20.11.1_arm64.deb -P ~/Downloads || echo 'Failed to download timeshift!'
    ssudo apt install -y --fix-broken ~/Downloads/timeshift_20.11.1_arm64.deb || echo 'Failed to install .deb file!'
    zenity --progress \
    --title="Installing Timeshift" \
    --text="Installing Timeshift, as soon as the process is completed you will have a shortcut in Menu > System-Tools" \
    --percentage=0|| echo 'Failed to install .deb file!'
    rm -f timeshift_20.11.1_arm64.deb*
    echo 
    echo "Process finished. It's recommended to make a backup with Timeshift to go back if something goes wrong."
    echo
    sleep 2
    fi
}
#Uninstall the program
if [ -f "$FILE" ] || [ -f "$FILEVENV" ]; then
 if zenity --question --title="Uninstall bauh" --text="Bauh is installed, do you want to uninstall it?"
    then
	   uninstall
       echo "Process completed."
       #alternativeapps
       exit 1
 fi
fi
#Installation 
#Description
if [ ! -f "$FILE" ]; then
   tfile=`mktemp`
   echo "
-The installer does't work properly? Contact us: fenixlinux.com
-This process may take an hour.
-You can uninstall Bauh, the Snap Store and Gnome-Software launching this again.
-Description: 
Bauh (ba-oo), formerly known as fpakman, is a graphical interface for managing your Linux software (packages/applications). It currently supports the following formats: AppImage, ArchLinux repositories/AUR, Flatpak, Snap and Web applications.
Key features:
A management panel where you can: search, install, uninstall, upgrade, downgrade and launch you applications (and more...)
Tray mode: it launches attached to the system tray and publishes notifications when there are software updates available
System backup: it integrates with Timeshift to provide a simple and safe backup process before applying changes to your system
Custom themes: it's possible to customize the tool's style/appearance. More at Custom themes."> "$tfile"
if zenity --text-info --title="About" --filename="$tfile"
 then
    #Delete about tmp file
    rm -f "$tfile"
    #Install a backup program
    REQUIRED_PKG="timeshift"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
    if zenity --question --title="Install timeshift" --text="Timeshift is a tool that allows you to create a restore point. Install it?"
     then
        timeshift
    fi
    fi
    #Install the program and dependencies
    echo "Updating the repositories:"
    sleep 1
    sudo apt update || zenity --error --title="Error" --text="Error updating  repositories, skipping." --no-wrap
    echo "Installing dependencies:"
    sleep 1
    sudo apt install python3 python3-pip  python3-pyqt5  python3-requests
    pip3 install --upgrade pip || zenity --error --title="Error" --text="Unable to upgrade pip." --no-wrap
    sudo apt install qt5-default pyqt5-dev pyqt5-dev-tools || zenity --error --title="Error" --text="Unable to install pqt5_default and dev packages." --no-wrap
    sudo apt install python-lxml || zenity --error --title="Error" --text="Unable to install python-lxml." --no-wrap
    sudo apt install sqlite3 fuse || zenity --error --title="Error" --text="Unable to install sqlite3 and fuse needed to run AppImge." --no-wrap
    echo "Installing bauh:"
    sleep 1
    pip3 install bauh   
    #python -m pip install bauh > Try to use this command in case of error.
    #Create shortcut
    mkdir ~/.local/share/icons
    wget -qnc --continue -O ~/.local/share/icons/bauh.png https://fenixlinux.com/images/2021/Bauh-logo-300x215.png
    echo "[Desktop Entry]
      Type=Application
      Name=Bauh
      GenericName=Bauh
      Comment=Graphical interface for managing your Linux software (packages/applications).
      Categories=System;
      Exec=$HOME/.local/bin/bauh
      Icon=$HOME/.local/share/icons/bauh.png
      StartupWMClass=Bauh" > ~/.local/share/applications/bauh.desktop  
    #Snapd and flatpak installation.
    #Snapd installation code thanks in part to rpcoder and urhixidur
        snapd
        flatpak
    #Launch the program
    PATH="$HOME/bin:$HOME/.local/bin:$PATH"
    if  [ ! -f "$FILE" ]; then
     echo -e "\n\n\n\nError, Bauh not found or is corrupted. You can delete the corrupted files by running this script again. Trying to install it in a virtual environment.\n\n\n\n" && installonvenv
    fi
    if zenity --question --title="Open bauh" --text="Do you want to launch bauh?"
    then
	 bauh 2>/dev/null || zenity --error --title="Error" --text="Error installing bauh in normal mode." --no-wrap
    fi
    if  [ ! -f "$FILEVENV" ]; then
    if zenity --question --title="Bauh_venv install" --text="Do you want to install the version of Bauh that works inside a virtual environment?"
    then
     installonvenv
    fi
    fi
    fi
    fi
    #Alternatives
    alternativeapps
	#Support
    if zenity --info  --width=400 \
    --text="That's all, don't forget to support the developers of these amazing applications if you like them."
        then
    xdg-open 'https://github.com/vinifmor/bauh' &>/dev/null
   	xdg-open 'https://fenixlinux.com/pdownload' &>/dev/null
    fi
    exit 1
    

