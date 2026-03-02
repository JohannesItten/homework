#!/bin/bash
test -f '/var/www/html/index.html'
ss -tulpn | grep '0.0.0.0:80'
