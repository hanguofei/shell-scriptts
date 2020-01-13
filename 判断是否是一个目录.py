#!/usr/bin/env python3

import os

dir = "/var/www/html/EnjoyCarApi/"
if os.path.isdir(dir):
    print('%s is a dir' % dir)
else:
    print('%s is not a dir' % dir)
