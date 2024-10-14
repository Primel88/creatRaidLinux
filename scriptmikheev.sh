#!/bin/bash

#create RAID

if [[ $? -eq 0 && $(sudo dpkg -s mdadm) && $(sudo dpkg -s pvcreate) ]]; then
 echo "OK All installed"
 else
 echo "Package will install"
 apt install mdadm
 apt install lvm2
fi

echo "Vvedi name Group"
read nameGroup

#read devices

sudo mdadm  --create /dev/md/$nameGroup /dev/sdb /dev/sdc /dev/sdd --level=1 --raid-devices=3

if [[ $? -eq 0 && $(sudo mdadm -D /dev/md/$nameGroup | grep 'State :' | cut -f 2 -d":" | sed 's/ //g')=='clean' && $(sudo mdadm -D /dev/md/$nameGroup | grep "Active Devices : 3") ]]; then
 echo "RAID create SUCCESSFULLY"
 else
 echo "FAILED RAID CREATE"
 exit 1
fi

echo "--------------------------------------------------------------"

#Initializaton RAID And proverka

sudo pvcreate /dev/md/$nameGroup

if [[ $? -eq 0 && $(ls /dev/md/ | grep $nameGroup) ]]; then
 echo "Create initialixation disks SUCCESSFULLY"
 else
 echo "Faile create initialization disks"
 exit 1
fi
    
echo "-------------------------------------------------------------"

#Create LVMGROUP

echo "Vvedit nazvanie LVMGROUP"
read NAMEVIRTGROUP

sudo vgcreate $NAMEVIRTGROUP /dev/md/$nameGroup

if [[ $? -eq 0 && $(sudo vgdisplay | grep "VG Name" | grep $NAMEVIRTGROUP) ]]; then
 echo "Create VIRTGROUP SUCCESSFULLY"
 else
 echo "FAILED VIRTGROUP create"
 exit 1
fi

echo "-----------------------------------------------------------"


#Create disk partions LVM

echo "Vvedite nazvanie LOGICVOLUNE"
read LOGICVOLUME

sudo lvcreate -l 100%FREE -n $LOGICVOLUME $NAMEVIRTGROUP

if [[ $? -eq 0 && $(sudo lvdisplay | grep "LV Name" | grep $LOGICVOLUME) ]]; then
 echo "CreateLogicVolume SUCCESSFULLY and cheked"
 else
 echo "FAILED create LogicVOlume"
 exit 1
fi

echo "----------------------------------------------------------"

#Formatation New Partion in EXT4

sudo mkfs.ext4 /dev/$NAMEVIRTGROUP/$LOGICVOLUME

if [[ $? -eq 0 && $(lsblk -f | grep ext4 | cut -f 4 -d" " | sed '1d' | sed 's/ //g')=='ext4' ]]; then
 echo "FORMATATION int ext4 SUCCESSFULLY"
 else
 echo "FAILED FORMATATION int ext4"
 exit 1
fi

echo "-----------------------------------------------------"

#check svoistva newgroup

CHECK=$(sudo vgdisplay $NAMEVIRTGROUP)
echo "checked"
echo $CHECK

echo "--------------------------------------------------"

#mount FS

sudo mount /dev/$NAMEVIRTGROUP/$LOGICVOLUME /mnt/
#check file
touch /mnt/my_path/new_file

if [[ $? -eq 0 && $(ls /mnt/my_path | grep new_file) ]]; then
 echo "uspechno mount SUCCESSFULLY"
 else
 echo " FAILED mount"
 exit 1
fi

rm /mnt/my_path/new_file
echo "---------------------------------------------------------"
  
echo "ITOG vivod"
blk=$(lsblk -f)
echo $blk
