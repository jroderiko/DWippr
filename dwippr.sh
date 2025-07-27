#!/bin/bash

. /path/to/DWippr/dw.conf

#////////////// VARIABLES //////////////#
USRSRC=""
WIPTYPE=""
DSKPATH="/dev/"
DMODEL=""
LOGPATH="$DW_LOGDIR"
LOGFILE=""
WRITEYN='n'
READREP='n'

#////////////// FUNCTIONS //////////////#

### Print list of disks, filtering out NONO_DISKS ###
printdisk() {
    if [[ ${#NONO_DISKS[@]} -eq 0 ]]; then
        lsblk -d -o NAME,SIZE,TYPE
    else
        local DONT_WIPE
        DONT_WIPE="$(printf "%s|" "${NONO_DISKS[@]}")"
        DONT_WIPE="${DONT_WIPE%|}"  # Remove trailing '|'
        lsblk -d -o NAME,SIZE,TYPE | grep -Ev "$DONT_WIPE"
    fi
}

### Update device info fields ###
fieldup() {
    printf "\nUpdating log fields...\n"

    case "$DSKPATH" in
        *sd*)
            DMODEL=$(smartctl -a "$DSKPATH" | grep 'Device Model')
            WIPTYPE="ATA"
            ;;
        *nvm*)
            DMODEL=$(smartctl -a "$DSKPATH" | grep 'Model')
            WIPTYPE="NVMe"
            ;;
        *)
            echo "Error: $DSKPATH not a valid device"
            exit 1
            ;;
    esac

    DSKSN=$(smartctl -a "$DSKPATH" | grep 'Serial')
    DSKTYPE+=" $WIPTYPE"
    SRCFIELD="Source: $DSKSRC"
}

### Perform wipe ###
wippit() {
    echo "Retrieving supported write methods..."

    case "$WIPTYPE" in
        NVMe)
            DMETHOD+=" NVMe CLI - "
            NVME_INFO=$(nvme id-ctrl -H "$DSKPATH")
#------------
#	filter out "No-Deallocate"
#	check grep logic
#------------
            if echo "$NVME_INFO" | grep -q "Sanitize" && ! echo "$NVME_INFO" | grep -q "Not Supported" ; then
                DMETHOD+="Sanitize"
                echo "Wiping $DSKPATH with $DMETHOD..."
                nvme sanitize "$DSKPATH"
            else
                DMETHOD+="Format"
                echo "Wiping $DSKPATH with $DMETHOD..."
                nvme format "$DSKPATH"
            fi
            ;;

        ATA)
            DMETHOD+=" hdparm"
            if hdparm -I "$DSKPATH" | grep -q "SANITIZE"; then
                DMETHOD+=" SANITIZE"
                echo "Wiping $DSKPATH with $DMETHOD..."
                hdparm --yes-i-know-what-i-am-doing --sanitize-block-erase "$DSKPATH"
		hdparm --sanitize-status "$DSKPATH"
            else
                DMETHOD+=" SECURE ERASE"
                echo "Wiping $DSKPATH with $DMETHOD..."
                hdparm --user-master u --security-set-pass PasSWorD "$DSKPATH"
                hdparm --user-master u --security-erase-enhanced PasSWorD "$DSKPATH"
            fi
            echo "DONE"
            ;;

        *)
            echo "Error: $WIPTYPE is not a supported type"
            exit 1
            ;;
    esac
}

### Generate report ###
reportgen() {

    LOGFILE="${LOGPATH}/${DSKSRC}.log"
    echo -e "\nGenerating log file: $LOGFILE"

    {
        echo "*** DWip Beta ${DWIP_VERSION} Report ***"
        echo ""
        echo "$(date) || $(date -u)"
        echo "$TECH"
        echo "$SRCFIELD"
        echo "$DSKTYPE"
        echo "$DMODEL"
        echo "$DSKSN"
        echo "$TOOL"
        echo "$DMETHOD"
        echo ""
        echo "SMART Health Report:"
        smartctl -a "$DSKPATH"
    } >> "$LOGFILE"
}

#////////////// MAIN SCRIPT //////////////#

echo -e "*** DWip Beta ${DWIP_VERSION} ***\n"

# Technician Name
read -rp "Enter your name: " name
TECH+="$name"

# Batch#
read -rp "Enter Batch#: " USRSRC
if ! [[ "$USRSRC" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid Batch#: use only letters, numbers, -, or _"
    exit 1
fi
DSKSRC+="$USRSRC"
echo ""

# List and select disks
echo "Available Disks:"
printdisk
echo ""
read -rp "Type disk name (e.g., sda, nvme0n1): " dsksel
DSKPATH+="$dsksel"

# Validate disk
if ! lsblk -d -o NAME | grep -qw "$dsksel"; then
    echo "Error: $DSKPATH is not a valid device!"
    exit 1
fi

# Confirm selection
echo -e "\n!!! Verify your selection !!!"
lsblk -d -o NAME,MODEL,SIZE | grep -w "$dsksel"
echo -e "\nAre you sure you want to wipe disk(s)? (y/N)"
read -r WRITEYN

# Start Wipe
case "$WRITEYN" in
    [yY])
        fieldup
        wippit
        reportgen
        ;;
    *)
        echo "Not wiping..."
        echo "Exiting DWip..."
esac

printf "\nWould you like to read the log? (y/N)\n"
read READREP
case "$READREP" in
	y | Y)
		cat $LOGFILE | more
		;;
	*)
		echo -e "\nDONE"
esac
[rawrchitect@
