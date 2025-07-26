#!/bin/bash
echo "*** DWippr Setup Script v1 ***"
echo ""

dwdir="$(pwd)"
printf "\nConfiguring Environment...\n"
logdir="DW_LOGDIR=$(realpath $dwdir)/logs" #potential issue with realpath usage
echo ""
echo "Log directory: $dwdir/logs"
echo "Config file: $dwdir/dw.conf"
printf "\nSelect disks to exclude from wipes\n"
lsblk -d
printf "\nType disk name (ex. sda) and hit Enter to continue\n"
printf "Type 'd' and hit Enter when you're done\n"
dsksel='/dev/'
NONO_DISKS=()
while [ $dsksel != "d" ]
do
	read dsksel
	if [[ $dsksel = "d" ]]; then
		echo -e "DONE\n"
	else	
		NONO_DISKS+=("$dsksel")
	fi
done
for ((i=0;i<${#NONO_DISKS[@]};i++))
do
	echo "NONO_DISK $i: ${NONO_DISKS[$i]}"
done

###############
#CREATE CONFIG#
###############
mkdir -p $dwdir/logs
touch $dwdir/dw.conf
### Add Log Directory to config
echo "# Version" >> $dwdir/dw.conf
echo 'DW_VERSION="1.0"' >> $dwdir/dw.conf
printf "\n# Log Path\n" >> $dwdir/dw.conf
echo "$logdir" >> $dwdir/dw.conf
### Add NONO_DISKS array to config file
printf "\n# You can add disks to exclude from DWippr here:\n" >> $dwdir/dw.conf
echo "# !!! Do not include '/dev/' !!!" >> $dwdir/dw.conf
echo "NONO_DISKS=(${NONO_DISKS[@]})" >> $dwdir/dw.conf

########################
# Add Prefixes to conf #
########################
printf "\n# Report Field Prefixes \n" >> $dwdir/dw.conf
echo 'TECH="Technician: "' >> $dwdir/dw.conf
echo 'DSKSRC="Batch#"' >> $dwdir/dw.conf
echo 'DSKTYPE="Media Type:"' >> $dwdir/dw.conf
echo 'TOOL="Tool: DWippr v1.0"' >> $dwdir/dw.conf
echo 'DMETHOD="Method:"' >> $dwdir/dw.conf
printf "\nDONE\n"
echo -e "\n!!! Important !!!\n"
echo "Please add this line to the beginning of dwippr.sh:"
echo ". $dwdir/dw.conf"
echo ""
echo ""

