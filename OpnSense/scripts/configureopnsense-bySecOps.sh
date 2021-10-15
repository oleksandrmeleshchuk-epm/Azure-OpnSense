#!/bin/sh
#OPNSense default configuration template
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/pw.php
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/config.xml
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/updateips.sh
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/updateips2.sh
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/updateips3.sh

sh ./updateips.sh 10.${1}.${2}.7 27 10.${1}.${2}.39 27 10.${1}.${2}.33 10.${1}.${2}.1 10.${1}.${2}.32 27 
sh ./updateips2.sh 10.${1}.${2}.64 26 10.${1}.${2}.9 10.${1}.${2}.11 172.31.${1}.0 24 10.${1}.${2}.0 24
sh ./updateips3.sh 10.${1}.${2}.128 26 172.17.${1}.0 24 4Y4qphauPflcarg610Bt jJVoAWEbgeeAqT9flN29
cp config.xml /usr/local/etc/config.xml

# 1. Package to get root certificate bundle from the Mozilla Project (FreeBSD)
# 2. Install bash to support Azure Backup integration
env IGNORE_OSVERSION=yes
pkg bootstrap -f; pkg update -f
env ASSUME_ALWAYS_YES=YES pkg install ca_root_nss && pkg install -y bash 

#Dowload OPNSense Bootstrap and Permit Root Remote Login
fetch https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in
sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

#OPNSense
sed -i "" "s/reboot/shutdown -r +1/g" opnsense-bootstrap.sh.in
sh ./opnsense-bootstrap.sh.in -y -r "21.7"
#Adds support to LB probe from IP 168.63.129.16
fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/scripts/lb-conf.sh
sh ./lb-conf.sh
