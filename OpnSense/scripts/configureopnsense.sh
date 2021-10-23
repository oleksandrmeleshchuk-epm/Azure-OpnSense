#!/bin/sh
#OPNSense default configuration template
echo "Will be tryinig to install OpnSense release ${2}";
fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/${3}/${1} > /dev/null 2>&1

if [ -f $1 ]; then
	sed -i '' -E -e 's/1.1.1.1/'10.${4}.${5}.7'/g' config.xml;
	sed -i '' -E -e 's/2.2.2.2/'27'/g' config.xml;
	sed -i '' -E -e 's/3.3.3.3/'10.${4}.${5}.39'/g' config.xml;
	sed -i '' -E -e 's/4.4.4.4/'27'/g' config.xml;
	sed -i '' -E -e 's/5.5.5.5/'10.${4}.${5}.33'/g' config.xml;
	sed -i '' -E -e 's/6.6.6.6/'10.${4}.${5}.1'/g' config.xml;
	sed -i '' -E -e 's/7.7.7.7/'10.${4}.${5}.32'/g' config.xml;
	sed -i '' -E -e 's/9.9.9.9/'27'/g' config.xml;
	sed -i '' -E -e 's/10.10.10.10/'10.${4}.${5}.64'/g' config.xml;
	sed -i '' -E -e 's/11.11.11.11/'26'/g' config.xml;
	sed -i '' -E -e 's/12.12.12.12/'10.${4}.${5}.9'/g' config.xml;
	sed -i '' -E -e 's/13.13.13.13/'10.${4}.${5}.11'/g' config.xml;
	sed -i '' -E -e 's/14.14.14.14/'172.31.${4}.0'/g' config.xml;
	sed -i '' -E -e 's/15.15.15.15/'24'/g' config.xml;
	sed -i '' -E -e 's/16.16.16.16/'10.${4}.${5}.0'/g' config.xml;
	sed -i '' -E -e 's/17.17.17.17/'24'/g' config.xml;
	sed -i '' -E -e 's/18.18.18.18/'10.${4}.${5}.128'/g' config.xml;
	sed -i '' -E -e 's/19.19.19.19/'26'/g' config.xml;
	sed -i '' -E -e 's/20.20.20.20/'172.17.${4}.0'/g' config.xml;
	sed -i '' -E -e 's/21.21.21.21/'24'/g' config.xml;
	sed -i '' -E -e 's/22.22.22.22/'${7}'/g' config.xml;
	sed -i '' -E -e 's/23.23.23.23/'${6}'/g' config.xml;

	# 1. Package to get root certificate bundle from the Mozilla Project (FreeBSD)
	# 2. Install bash to support Azure Backup integration
	
	if ( grep "IGNORE_OSVERSION" /etc/csh.cshrc );  then
		echo "IGNORE_OSVERSION is already added"
	else
		echo "setenv IGNORE_OSVERSION yes" >> /etc/csh.cshrc;
	fi
	
	if ( grep "ASSUME_ALWAYS_YES" /etc/csh.cshrc );  then
		echo "ASSUME_ALWAYS_YES is already added"
	else
		echo "setenv ASSUME_ALWAYS_YES yes" >> /etc/csh.cshrc;
	fi
	
	pkg bootstrap -f; pkg update -f;
	pkg install ca_root_nss && pkg install -y bash && pkg install -y jq && pkg install -y curl;
	echo "Generating hash from the provided value"
	curl -s -X POST --data "password=${8}&cost=10" https://bcrypt.org/api/generate-hash.json |  jq -r '.hash' > ./hash;

	if [ -s ./hash ]; then
		echo "Hash file exists, proceeding"
		PASSWD=`cat "./hash"`
		if [ $PASS ]; then
			echo "PASS variable set, proceeding"
			sed -i '' -E -e 's|24.24.24.24|'$PASSWD'|g' config.xml;
		else
			echo "PASS variable is empty, exiting"
			exit 1
		fi
		cp -f config.xml /usr/local/etc/config.xml
		#Dowload OPNSense Bootstrap and Permit Root Remote Login
		fetch https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in > /dev/null 2>&1
		sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config;
		#OPNSense
		sed -i "" "s/reboot/shutdown -r +1/g" opnsense-bootstrap.sh.in;
		
		echo "Starting OpnSense installation"
		sh opnsense-bootstrap.sh.in -y -r ${2};
		
		echo "Checking if /conf/config.xml file exists"
		if [ -f /conf/config.xml ]; then
			#Adds support to LB probe from IP 168.63.129.16
			fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/scripts/lb-conf.sh > /dev/null 2>&1
			sh ./lb-conf.sh
			rm -rf hash
			shutdown -r +1
		else
			echo "OpnSense installation failed, exiting"
			exit 1
		fi
	else
		echo "Hash file does not exist, exiting"
		exit 1
	fi
else
	echo "$1 file does not exist, exiting"
	exit 1
fi
