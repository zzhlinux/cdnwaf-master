#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

WORD_DIR="/tmp/.cdnwaf"


# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}


Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}


Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
    fi
}

Get_RHEL_Version()
{
    if [ "${DISTRO}" = "CentOS" ]; then
        if grep -Eqi "release 6." /etc/redhat-release; then
            RHEL_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            RHEL_Ver='7'
        fi
  fi
}



Get_Dist_Name
Get_RHEL_Version


# Script Varibles
SCRIPT_DIR="$(cd -P "$( dirname "${BASH_SOURCE[0]}" )" ; pwd)"
SKIP=$(awk '/^### END OF THE SCRIPT ###/ { print NR + 1; exit 0; }' $0)

if  [[ "${DISTRO}" = 'CentOS' && "${RHEL_Ver}" = '7' ]];then
      SYS_VER="centos-7"
      clear
      echo "系统 $SYS_VER , 正在安装cdnwaf主控，请稍等………………"
      rpm -q epel-release &> /dev/null || yum install epel-release -y >/dev/null |grep -v 'Error'
      rpm -q jq &> /dev/null || yum install jq -y 2&>/dev/null |grep -v 'Error'
      rpm -q curl &> /dev/null || yum install curl -y >/dev/null  |grep -v 'Error'
      rpm -q tee &> /dev/null || yum install tee -y >/dev/null |grep -v 'Error'

      CODE=$1
      CODEDIR='/tmp/.cdnwaf.json'
      curl -s "http://yapi.spstak.vip/mock/18/cdnwaf/auth?code=$CODE?verify=www.cdnwaf.cn" |jq > /tmp/.cdnwaf.json
      CODE_STATUS=$([ ! -z $CODE ] && echo ok || echo null)
      CDN_STATUS=$(cat $CODEDIR  |jq -r .status)

      if [[ "$CODE_STATUS" == "ok" && "$CDN_STATUS" == "ok" ]]; then
           echo "cdnwaf 授权码 正确" && sleep 3
           MA_IP=$(cat $CODEDIR |jq -r .IP)
           ES_PASS=$(cat $CODEDIR |jq -r .EP)
           DNS_IP=$(cat $CODEDIR |jq -r .dns)
           ES_DIR=$(cat $CODEDIR |jq -r .ED)
           echo "$ES_PASS" > /opt/es_pwd
           grep -q "$DNS_IP" /etc/resolv.conf || sed -i "1i nameserver $DNS_IP" /etc/resolv.conf
           rm -rf $CODEDIR
           total_mem=`awk '/MemTotal/{print $2}' /proc/meminfo`
           HEAP_SIZE=`awk -v total_mem=$total_mem 'BEGIN{printf ("%.0f", total_mem*0.4/1024)}'`
           #echo "CODE:$CODE , CODEDIR:$CODEDIR , CODE_STATUS:$CODE_STATUS , CDN_STATUS:$CDN_STATUS , MA_IP:$MA_IP , ES_PASS:$ES_PASS , DNS_IP:$DNS_IP , ES_DIR:$ES_DIR"
      else
           echo "cdnwaf 授权码为空，或不正确"
           echo "$0 授权码"
           exit 1
      fi
else
      echo "目前只支持Centos-7"
      exit 1
fi


if [ ! -d "$WORD_DIR" ];then
   mkdir -p $WORD_DIR
   tail -n +${SKIP} $0 | tar -zpxC $WORD_DIR
else
   rm -rf $WORD_DIR && mkdir -p $WORD_DIR
   tail -n +${SKIP} $0 | tar -zpxC $WORD_DIR
fi

### WARNING: Do not modify the following !!!

