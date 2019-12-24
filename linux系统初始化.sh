#!/bin/bash

#

#********************************************************************

#encoding  -*-utf8-*-

#Author:

#Date: 2018-12-19

#URL:

#Description：   The test script

#Copyright (C): 2018 All rights reserved

#QQ Numbers:

#********************************************************************

read -p "请输入IP地址:" IP

read -p "请输入GATEWAY地址:" GATEWAY

read -p "请输入主机名:" HOST_NAME

read -p "是否创建ywuser用户:(Yes/No)" ADD_YWUSER

#查看系统版本

Get_host_version=`cat /etc/centos-release | grep -i centos | grep -o "\<[[:digit:]]\+" |head -1`

#查看内核版本

kernel_version=`uname -r`

#设置开机启动文件的权限

chmod +x /etc/rc.d/rc.local

#zabbix-server IP地址

ZABBIX_SERVER=10.180.4.230

#修改主机名HOST_NAME

function Set_HOST_NAME(){

    if [ "$Get_host_version" == 7 ]

        then

        hostnamectl set-hostname $HOST_NAME &>/dev/null

        echo "$IP $HOST_NAME" >/etc/hosts

    elif [ "$Get_host_version" == 6 ]

        then

        hostname $HOST_NAME &>/dev/null

        chkconfig iptables off &>/dev/null

echo "$IP $HOST_NAME" >/etc/hosts

sed -ri "s@^(HOSTNAME=).*$@\1\$HOST_NAME@g" /etc/sysconfig/network

    else

        Error_system_version

        return 1

    fi

}

#是否创建ywuser用户，并设置sudo权限。

function Add_ywuser(){

    case $ADD_YWUSER in

    [Yy]|[Yy][Ee][Ss])

            ADD_YWUSER=Y

            ;;

    [Nn]|[Nn][Oo])

            ADD_YWUSER=N

            ;;

    *)

            echo other

            return 1

            ;;

    esac 

    if [ "$ADD_YWUSER" == Y ]

        then

            useradd ywuser

            echo 'SDGSxlzf@123' | passwd --stdin  "ywuser"

            echo 'ywuser    ALL=(ALL)      ALL' >>/etc/sudoers

            echo 'ywuser用户已创建完成'

    else

        echo '跳过创建ywuser用户'

    fi

}

#修改提示符颜色信息

function set_Prompt(){

    echo 'export PS1="\[\e[1;32m\][\u@\h \w]\\$\[\e[m\]"' >>/root/.bashrc

    echo 'export PS1="\[\e[1;32m\][\u@\h \w]\\$\[\e[m\]"' >>/etc/skel/.bashrc 

    echo 'alias grep="grep --color" ' >>/root/.bashrc

    echo 'alias grep="grep --color" ' >>/etc/skel/.bashrc 

    echo -e "syntax on\nset number" >>/etc/vimrc

    echo -e "严正声明，如果您以非法方式登录本服务器，您将承担法律责任！！！\nI declare that if you log on this server by illegal means, you will be held legally responsible!!!" >>/etc/motd

    PS1="\[\e[1;32m\][\u@\h \w]\\$\[\e[m\]"

}

#修改history提示增加时间和用户

function set_History(){

    echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >>/etc/profile

}

#备份操作的相关目录

function Bakup_etc(){

    Now_of_time=`date +'%F_%H.%M'`

    back_path=/bak/initsys/

    mkdir -p $back_path

    tar -czf $back_path/etc.${Now_of_time}.tar.gz /etc

}

#设置默认启动时用字符界面

function Set_multi_start(){

    #off firewall

    if [ "$Get_host_version" == 7 ]

        then

        systemctl set-default multi-user.target

    elif [ "$Get_host_version" == 6 ]

        then

        sed -i 's/id:5:initdefault:/id:3:initdefault:/g' /etc/inittab

    else

        sed -i 's/id:5:initdefault:/id:3:initdefault:/g' /etc/inittab

        return 1

    fi

}

#禁止Ctrl+Alt+Del快捷键重新启动

function Close_ctrl_alt_del(){

    #off firewall

    if [ "$Get_host_version" == 7 ]

        then

        rm -f /usr/lib/systemd/system/ctrl-alt-del.target

    elif [ "$Get_host_version" == 6 ]

        then

        sed -i 's/^exec/#exec/g' /etc/init/control-alt-delete.conf

    else

        sed -i 's/^exec/#exec/g' /etc/init/control-alt-delete.conf

        return 1

    fi

}

#设置300秒无操作自动注销ROOT

function Automatic_log-out(){

    sed -i '/HISTSIZE=/a\TMOUT=300' /etc/profile

}

#关闭防火墙和selinux

function Off_firewall_and_selinux(){

    #off firewall

    if [ "$Get_host_version" == 7 ]

        then

        systemctl stop firewalld &>/dev/null

        systemctl disable firewalld &>/dev/null

    elif [ "$Get_host_version" == 6 ]

        then

        service iptables stop &>/dev/null

        chkconfig iptables off &>/dev/null

    else

        Error_system_version

        return 1

    fi

    #off selinux

    sed -ri 's/^(SELINUX=).*$/\1disabled/g' /etc/selinux/config

    setenforce 0

}

#配置时区和时间

function Set_timezone_and_time(){

    /usr/bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    /usr/sbin/ntpdate 10.180.4.204 #设置ntp服务器同步，如果需要取消注释

    hwclock -w #同步系统时间到硬件时间

    if [ "$Get_host_version" == '6' ]

        then

        cat > /etc/sysconfig/clock << EOF

ZONE="Asia/Shanghai"

UTC=false

ARC=false

EOF

    elif [ "$Get_host_version" == '7' ]

        then

        timedatectl set-local-rtc yes

    else

        Error_system_version

    fi   

}

#测试外网是否连通

function Test_network(){

    ping -c1 www.baidu.com &>/dev/null

    if [ $? -eq 0 ]

        then

        return 0

    else

        return 1

    fi

}

#设置系统最大句柄数

function Set_handler_Num(){

    limit_count=`cat /etc/security/limits.conf | grep "^\*[[:blank:]]\+\(soft\|hard\)[[:blank:]]\+\(nofile\|nproc\)[[:blank:]]\+" | wc -l`

    if [ "$limit_count" -eq 0 ]

        then

        cat >> /etc/security/limits.conf << EOF

*  soft  nofile  102400

*  hard  nofile  102400

*  soft  nproc    40960

*  hard  nproc    40960

EOF

        ulimit -n 102400 #设置文件打开数,并马上生效，

    else

        echo "已经添加过limit限制!"

    fi

}

#禁用ssh的DNS功能

function Disabled_sshd_dns(){

    [ `grep "^#UseDNS \(no\|yes\)" /etc/ssh/sshd_config | wc -l` -eq 0 ] && { echo '已禁用该配置，Do nothing！' ; return 1; }

    sed -ri 's@#UseDNS (no|yes)@UseDNS no@g' /etc/ssh/sshd_config

    if [ "$Get_host_version" == '6' ]

        then

        service sshd restart

    elif [ "$Get_host_version" == '7' ]

        then

        systemctl restart sshd

    else

        Error_system_version

    fi

}

#配置网卡名称为eth*

function Modify_network_card_name(){

    if [ "$Get_host_version" == '6' ] #修改Centos6 的网卡

        then

        Count_cart=`cat /etc/udev/rules.d/70-persistent-net.rules | grep 'SUBSYSTEM=="net", ACTION=="add"' | wc -l`

        [ "$Count_cart" -eq 0 ] && { echo "没有网卡信息，请检查网卡驱动！" ; return 1; }

        count=1

        All_mac=`cat 70-persistent-net.rules | grep 'SUBSYSTEM=="net", ACTION=="add"' |grep -o "\([0-9a-fA-F]\{2\}:\)\{5\}[0-9a-fA-F]\{2\}"`

        for i in `$ALL_mac`

            do

            sed -ri 's@('$i'.*NAME=").*[[:digit:]]+"$@\1eth'$count'$"@' /etc/udev/rules.d/70-persistent-net.rules

            let count+=1

            done

        echo '修改网卡名成功,请查看配置!'

        echo "`cat /etc/udev/rules.d/70-persistent-net.rules | grep 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="'`"

    elif [ "$Get_host_version" == '7' ] #修改Centos7 的网卡

        then

        boot_grub=/boot/grub2/grub.cfg

        grub_default_cfg=/etc/default/grub

        Name_count=`cat  $boot_grub 2>/dev/null | grep "quiet[[:blank:]]\+net.ifnames" | wc -l`

        cp $grub_default_cfg ${grub_default_cfg}.`date +'%F_%H.%M'`

        [ $? -ne 0 ] && { echo "没有 $grub_default_cfg 这个文件" ; return 1; }

        if [ "$Name_count" -eq 0 ]

            then

            sed -ri 's/(GRUB_CMDLINE_LINUX=.*quiet)/\1 net.ifnames=0/g' $grub_default_cfg

            grub2-mkconfig -o $boot_grub

            if [ $? -eq 0 ]

                then

                echo '生成新的配置文件，生效需重启！'

            else

                echo "grub文件生成错误！ $boot_grub 可能会产生错误！请检查"

            fi

        else

            echo '已经修改过grub参数，无需再次修改！Do nothing！'

        fi

    else

        Error_system_version

    fi

}

function Set_ip_gateway() {

NETWORK=/etc/sysconfig/network-scripts

mv $NETWORK/ifcfg-ens160 $NETWORK/ifcfg-eth0

cat > $NETWORK/ifcfg-eth0 << EOF

TYPE=Ethernet

PROXY_METHOD=none

BROWSER_ONLY=no

BOOTPROTO=static

DEFROUTE=yes

IPV4_FAILURE_FATAL=no

NAME=eth0

DEVICE=eth0

ONBOOT=yes

IPADDR=$IP

NETMASK=255.255.255.0

GATEWAY=$GATEWAY

PREFIX=24

IPV6INIT=no

EOF

}

function Set_zabbix_agent() {

rpm -ivh /usr/local/src/zabbix-agent-3.2.3-1.el6.x86_64.rpm

cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak

    mkdir -pv /var/run/zabbix/

    chown zabbix:zabbix /var/run/zabbix/

sed -i "s/^\(ServerActive=\).*$/\1$ZABBIX_SERVER/g" /etc/zabbix/zabbix_agentd.conf

sed -i "s/^\(Server=\).*$/\1$ZABBIX_SERVER/g" /etc/zabbix/zabbix_agentd.conf

sed -i "s/^\(Hostname=\).*$/\1$HOST_NAME/g" /etc/zabbix/zabbix_agentd.conf

echo 'HostMetadataItem=system.uname' >>/etc/zabbix/zabbix_agentd.conf

echo 'HostMetadata=sdgsautoreg'>>/etc/zabbix/zabbix_agentd.conf

}

#添加自启动服务

function Set_AUTO_services(){

    if [ "$Get_host_version" == 7 ]

        then

systemctl enable zabbix-agent &>/dev/null

    /sbin/chkconfig zabbix-agent on &>/dev/null

    reboot

    elif [ "$Get_host_version" == 6 ]

        then

        chkconfig zabbix-agent on &>/dev/null

    chkconfig --add zabbix-agent &>/dev/null

        reboot

    else

        Error_system_version

        return 1

    fi

}

#这里开始调用执行

Bakup_etc  #备份etc

Off_firewall_and_selinux  #关闭selinux

Set_timezone_and_time  #设置时区和时间

Set_handler_Num  # 设置打开文件数

Add_ywuser  #是否创建ywuser用户，并设置sudo权限

set_Prompt  #修改提示符信息

set_History #修改history提示增加时间和用户

Set_multi_start #设置默认启动时用字符界面

Close_ctrl_alt_del  #禁止Ctrl+Alt+Del快捷键重新启动

Automatic_log-out  #设置300秒无操作自动注销ROOT

Disabled_sshd_dns #禁用ssh的dns功能

Modify_network_card_name  #统一网卡名称为eth

Set_ip_gateway  #设置IP地址网关

Set_HOST_NAME   #设置hostname主机名

Set_zabbix_agent #设置zabbix-agent

Set_AUTO_services #添加自启动服务
