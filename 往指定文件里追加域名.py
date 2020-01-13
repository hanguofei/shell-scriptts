import sys
import re

#判断有无传入第二个参数
if len(sys.argv)==3:
      ip=sys.argv[2]
      sys.argv[2]="3600"
else:
    ip=sys.argv[3]

#判断ip是否有效
import socket
def checkIP(strIP):
    try:
        socket.inet_aton(strIP)
        return True
    except socket.error:
        return False


if checkIP(ip):
    with open('/root/桌面/域名.txt','a',encoding='utf-8')as f:
        f.write(sys.argv[1]+" "+sys.argv[2]+" "+"IN A"+" "+ip+ '\n')
        print("写入成功")   
else:
    print("IP无效")

