#!/bin/sh
#OPNSense default configuration template
fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/${3}/${1}
fetch https://raw.githubusercontent.com/wjwidener/update/master/bootstrap/pw.php
sed -i '' -E -e 's/1.1.1.1/'10.${4}.${5}.7'/g' config.xml
sed -i '' -E -e 's/2.2.2.2/'27'/g' config.xml
sed -i '' -E -e 's/3.3.3.3/'10.${4}.${5}.39'/g' config.xml
sed -i '' -E -e 's/4.4.4.4/'27'/g' config.xml
sed -i '' -E -e 's/5.5.5.5/'10.${4}.${5}.33'/g' config.xml
sed -i '' -E -e 's/6.6.6.6/'10.${4}.${5}.1'/g' config.xml
sed -i '' -E -e 's/7.7.7.7/'10.${4}.${5}.32'/g' config.xml
sed -i '' -E -e 's/9.9.9.9/'27'/g' config.xml
sed -i '' -E -e 's/10.10.10.10/'10.${4}.${5}.64'/g' config.xml
sed -i '' -E -e 's/11.11.11.11/'26'/g' config.xml
sed -i '' -E -e 's/12.12.12.12/'10.${4}.${5}.9'/g' config.xml
sed -i '' -E -e 's/13.13.13.13/'10.${4}.${5}.11'/g' config.xml
sed -i '' -E -e 's/14.14.14.14/'172.31.${4}.0'/g' config.xml
sed -i '' -E -e 's/15.15.15.15/'24'/g' config.xml
sed -i '' -E -e 's/16.16.16.16/'10.${4}.${5}.0'/g' config.xml
sed -i '' -E -e 's/17.17.17.17/'24'/g' config.xml
sed -i '' -E -e 's/18.18.18.18/'10.${4}.${5}.128'/g' config.xml
sed -i '' -E -e 's/19.19.19.19/'26'/g' config.xml
sed -i '' -E -e 's/20.20.20.20/'172.17.${4}.0'/g' config.xml
sed -i '' -E -e 's/21.21.21.21/'24'/g' config.xml
sed -i '' -E -e 's/22.22.22.22/'${7}'/g' config.xml
sed -i '' -E -e 's/23.23.23.23/'${6}'/g' config.xml
cp -f $1 /usr/local/etc/config.xml

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
sh ./opnsense-bootstrap.sh.in -y -r "${2}"

setenv FWPW `php pw.php ${8}`
sed -i '' -E -e 's|24.24.24.24|'$FWPW'|g' config.xml
cp -f $1 /usr/local/etc/config.xml

#Adds support to LB probe from IP 168.63.129.16
fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/scripts/lb-conf.sh
sh ./lb-conf.sh


shutdown -r +1