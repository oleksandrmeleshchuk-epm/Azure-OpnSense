#!/bin/sh
echo "Will be tryinig to install OpnSense release ${6}";

if [ -n "$6" ]; then
	if grep -q IGNORE_OSVERSION /etc/csh.cshrc; then
		echo "IGNORE_OSVERSION is already added"
	else
		echo "IGNORE_OSVERSION variable does not exist, adding"
		echo "setenv IGNORE_OSVERSION yes" >> /etc/csh.cshrc
	fi
	
	if grep -q IGNORE_OSVERSION /etc/csh.cshrc; then
		echo "IGNORE_OSVERSION has been successfully added"
	else
		echo "IGNORE_OSVERSION has not been added"
	fi
	env ASSUME_ALWAYS_YES=YES pkg bootstrap -f; pkg update -f
	env ASSUME_ALWAYS_YES=YES pkg install ca_root_nss && pkg install -y bash 
	
	if ( `! pkg info curl` ); then
		pkg install -y curl;
		if ! pkg info curl ; then
			echo "Package curl missing, exiting. Please check package availability"
			exit 1
		fi
	fi
	
	curl @raw.githubusercontent.com/${4}/${3}/${2}/${1}?token=${5} --output $1
	#curl -s https://${5}@raw.githubusercontent.com${4}/${3}/${2}/${1} --output $1
	cp $1 /usr/local/etc/config.xml

	#Dowload OPNSense Bootstrap and Permit Root Remote Login
	fetch https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in > /dev/null 2>&1
	sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config;
	sed -i "" "s/reboot/shutdown -r +1/g" opnsense-bootstrap.sh.in;
	
	echo "Starting OpnSense installation"
	sh opnsense-bootstrap.sh.in -y -r ${6};
	
	echo "Checking if /usr/local/etc/config.xml file exists"
	if [ -f /usr/local/etc/config.xml ]; then
		#Adds support to LB probe from IP 168.63.129.16
		fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/scripts/lb-conf.sh > /dev/null 2>&1
		sh ./lb-conf.sh
		shutdown -r +1
	else
		echo "OpnSense installation failed, exiting"
		exit 1
	fi
else
	echo "OpnSense version have not been set, exiting"
	exit 1
fi