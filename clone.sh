#!/bin/sh
# Скрипт клонирования эталонной машины
#
#
#

clear
echo ''>cur_mac_list.txt
run_flag="true"

#lvs $4 > /dev/null
#if [ $? -ne 0 ]
#then
#echo "sorry, vg '$4' does not exist"
#run_flag="false"
#else
#run_flag="true"
#fi

# syntax: is_number 12
#is_number()
#{
#[[ $1 =~ "^[0-9]+$" ]] && exit 0 || exit 1
#exit 0
#}

#is_number $3
#if [ $? -ne 0 ]
#then
#echo "sorry, parameter 3 must be a number"
#run_flag="false"
#else
#run_flag="true"
#fi

#is_number $2
#if [ $? -ne 0 ]
#then
#echo "sorry, parameter 2 must be a number"
#run_flag="false"
#else
#run_flag="true"
#fi

#echo $run_flag

#if [ $run_flag=="false" ]
#then
#exit 1
#fi

if [ $4 -z ]
then
echo "try run as: $0 etalon-machine-name X Y PATH_TO_LVM_VG"
echo ""
echo "where:"
echo "X -- clone-machine suffix-from which append to etalon-machine-name such as 'etalon-machine-name-X'"
echo "Y -- clone-machine suffix-to"
echo "PATH_TO_LVM_VG -- where is allocated virtual hdd from etalon-machine-name"
echo ""
echo "example:"
echo "$0 win7-lab1 1 5 '/dev/vg1'"
echo "will create 5 clones of existing virtmachine 'win7-lab1' which hdd location is /dev/vg1"
exit 0
fi


source_machine=$1
dest_machine_from=$2
dest_machine_to=$3
vg_path=$4
virsh="/usr/bin/virsh"

# syntax: get_rand 8
#         get_rand 4
#         e.t.c..
get_rand()
{
(date; cat /proc/interrupts) | md5sum | sed -r "s/^(.{$1}).*$/\1/; s/([0-9a-f]{$1})/\1/g;"
}

get_uid()
{
echo $(get_rand 8)-$(get_rand 4)-$(get_rand 4)-$(get_rand 4)-$(get_rand 12)
}

# get random mac
get_mac()
{
echo "00:"`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
}

# syntax: get_config $source_machine $i $vg_path
get_config()
{
echo "make config for $1-$2 ..."

uuid=$(get_uid)
mac=$(get_mac)
echo $mac >> cur_mac_list.txt
lv="$(echo $3 | sed 's/\//\\\//g')\/$1-$2"
#echo $uuid
#echo $mac
$virsh dumpxml $1 | sed "s/<mac address='.*'\/>/<mac address='$mac'\/>/g" |
sed "s/<uuid>.*<\/uuid>/<uuid>$uuid<\/uuid>/g" |
sed "s/<name>.*<\/name>/<name>$1-$2<\/name>/g" |
sed "s/<source dev='.*'\/>/<source dev='$lv'\/>/g" > /tmp/$1-$2.xml
echo "done."

echo "add configuration $1-$2 to kvm..."
$virsh define /tmp/$1-$2.xml
echo "done."

echo "make clone from $3/$1 to $3/$1-$2 (it may will take maaaaaaaaaaaany time...)..."
$virsh vol-clone $3/$1 $1-$2
echo "done."

echo "MACHINE $1-$2 IS READY"
echo "--"
echo ""
}

# make clones in loop
for i in $(seq $dest_machine_from $dest_machine_to)
do
get_config $source_machine $i $vg_path
done
