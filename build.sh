#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


## Defines the name of the generated binary package
Script_name="cdnwaf-install"
Script_pwd=$(cd "$(dirname "$0")";pwd)

echo -e "\033[33m Environment preparation, please wait ………… \033[0m"
rpm -q epel-release &> /dev/null || yum install epel-release -y &>/dev/null

yum_package="gcc-c++ shc"
for i in "$yum_package"
do
  rpm -q $i &> /dev/null || yum install $i -y
done



## Making binary packages
clear
echo -e "\033[33m Production in progress, please wait ………… \033[0m"
[ -d "${Script_pwd}/package" ] || mkdir -p  ${Script_pwd}/package
[ -f "${Script_pwd}/package/file.tar" ] && rm -rf ${Script_pwd}/package/file.tar
cd ${Script_pwd}/src && tar -czpf ${Script_pwd}/package/file.tar ./*

cd ${Script_pwd} && rm -rf ${Script_pwd}/build/install_all.sh.*
cat ${Script_pwd}/build/init.sh            > ${Script_pwd}/build/install_all.sh
cat ${Script_pwd}/shell/cdnwaf-install.sh >> ${Script_pwd}/build/install_all.sh

shc -r  -U  -f ${Script_pwd}/build/install_all.sh
[ -f "${Script_pwd}/${Script_name}" ] && mv ${Script_pwd}/${Script_name}  ${Script_pwd}/${Script_name}_$(date "+%Y%m%d-%H%M%S")
mv  ${Script_pwd}/build/install_all.sh.x  ${Script_pwd}/${Script_name}
echo -e "\n### END OF THE SCRIPT ###"   >> ${Script_pwd}/${Script_name}
cat ${Script_pwd}/package/file.tar      >> ${Script_pwd}/${Script_name}
chmod +x ${Script_pwd}/${Script_name}

[ -f "${Script_pwd}/${Script_name}" ] && echo "Script generated successfully  ${Script_pwd}/${Script_name}"
