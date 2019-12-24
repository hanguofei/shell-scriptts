#!/bin/bash
#ssh免密登录shell脚本
#配置免密登录的所有机子都要运行该脚本
 
#修改/etc/ssh/sshd_config配置文件
#sed -i 's/被替换的内容/替换成的内容/'  /配置文件地址
#sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
#cat >> /etc/ssh/sshd_config <<EOF
#RSAAuthentication yes
#EOF
 
yum install expect  #安装expect
echo "按enter键3次即可"
ssh-keygen -t rsa   #生成秘钥（按enter键3次即可生成）
SERVERS="spark12 spark13 spark14"   #需要配置的主机名
PASSWORD=123   #需要配置的主机登录密码
 
#将本机生成的公钥复制到其他机子上
#如果（yes/no）则自动选择yes继续下一步
#如果password:怎自动将PASSWORD写在后面继续下一步
auto_ssh_copy_id(){
        expect -c "set timeout -1;
        spawn ssh-copy-id $1;                                
        expect {
                *(yes/no)* {send -- yes\r;exp_continue;}
                *password:* {send -- $2\r;exp_continue;}  
                eof        {exit 0;}
        }";
}
 
ssh_copy_id_to_all(){
        for SERVER in $SERVERS #遍历要发送到各个主机的ip
        do
                auto_ssh_copy_id $SERVER $PASSWORD
        done
}
ssh_copy_id_to_all
