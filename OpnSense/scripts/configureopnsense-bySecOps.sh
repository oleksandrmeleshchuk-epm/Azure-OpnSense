#!/bin/sh
#OPNSense default configuration template
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/pw.php
fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/config-bySecOps.xml

sed -i '' -E -e 's/1.1.1.1/'10.${1}.${2}.7'/g' config-bySecOps.xml
sed -i '' -E -e 's/2.2.2.2/'27'/g' config-bySecOps.xml
sed -i '' -E -e 's/3.3.3.3/'10.${1}.${2}.39'/g' config-bySecOps.xml
sed -i '' -E -e 's/4.4.4.4/'27'/g' config-bySecOps.xml
sed -i '' -E -e 's/5.5.5.5/'10.${1}.${2}.33'/g' config-bySecOps.xml
sed -i '' -E -e 's/6.6.6.6/'10.${1}.${2}.1'/g' config-bySecOps.xml
sed -i '' -E -e 's/7.7.7.7/'10.${1}.${2}.32'/g' config-bySecOps.xml
sed -i '' -E -e 's/9.9.9.9/'27'/g' config-bySecOps.xml
sed -i '' -E -e 's/10.10.10.10/'10.${1}.${2}.64'/g' config-bySecOps.xml
sed -i '' -E -e 's/11.11.11.11/'26'/g' config-bySecOps.xml
sed -i '' -E -e 's/12.12.12.12/'10.${1}.${2}.9'/g' config-bySecOps.xml
sed -i '' -E -e 's/13.13.13.13/'10.${1}.${2}.11'/g' config-bySecOps.xml
sed -i '' -E -e 's/14.14.14.14/'172.31.${1}.0'/g' config-bySecOps.xml
sed -i '' -E -e 's/15.15.15.15/'24'/g' config-bySecOps.xml
sed -i '' -E -e 's/16.16.16.16/'10.${1}.${2}.0'/g' config-bySecOps.xml
sed -i '' -E -e 's/17.17.17.17/'24'/g' config-bySecOps.xml

FWPW=`php pw.php 4Y4qphauPflcarg610Bt`
OXIPW=`php pw.php jJVoAWEbgeeAqT9flN29`
sed -i '' -E -e 's/18.18.18.18/'10.${1}.${2}.128'/g' config-bySecOps.xml
sed -i '' -E -e 's/19.19.19.19/'26'/g' config-bySecOps.xml
sed -i '' -E -e 's/20.20.20.20/'172.17.${1}.0'/g' config-bySecOps.xml
sed -i '' -E -e 's/21.21.21.21/'24'/g' config-bySecOps.xml
sed -i '' -E -e 's|22.22.22.22|'$FWPW'|g' config-bySecOps.xml
sed -i '' -E -e 's|23.23.23.23|'$OXIPW'|g' config-bySecOps.xml

cp config-bySecOps.xml /usr/local/etc/config.xml

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
