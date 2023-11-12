<####################################################################
#>

clear-host

$ISOdisk = read-host -Prompt "Enter the disk where the OS is mounted"
$ISOdisk += ":\"
set-location $ISOdisk\boot

$bootDisk = read-host -Prompt "Enter the disk for the boot drive"
$bootDisk += ":"

bootsect /nt60 $bootDisk

$bootDisk+="\"

#$copyArg = $ISOdisk + "*.* " + $bootDisk + " /E /H /F"
#xCopy $copyArg #xCopy is DOS command, will not work with PS

#copy-item -path $ISOdisk* -destination $bootDisk -force -recurse -verbose