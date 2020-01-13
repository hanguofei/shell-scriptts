#!/usr/bin/env python3

import IPy

ip = IPy.IP('172.16.0.0/26')

print(ip.len())
for i in ip:
    print(i)
