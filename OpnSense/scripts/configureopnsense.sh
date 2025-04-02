#!/bin/sh
#OPNSense default configuration template
echo "Will be tryinig to install OpnSense release ${2}";

if [ -n "$8" ]; then
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
	# 1. Package to get root certificate bundle from the Mozilla Project (FreeBSD)
	# 2. Install bash to support Azure Backup integration
	env ASSUME_ALWAYS_YES=YES pkg bootstrap -f; pkg update -f
	env ASSUME_ALWAYS_YES=YES pkg install ca_root_nss && pkg install -y bash 
	
	if ( `! pkg info jq` ); then
		pkg install -y jq;
		if ! pkg info jq ; then
			echo "Package jq missing, exiting. Please check package availability"
			exit 1
		fi
	fi
	
	if ( `! pkg info curl` ); then
		pkg install -y curl;
		if ! pkg info curl ; then
			echo "Package curl missing, exiting. Please check package availability"
			exit 1
		fi
	fi

	echo "Generating hash from the provided value"
	#set -o pipefail # if supported by your shell
	# PASSWD=$(curl -s -X POST --data "password=${8}&cost=10" https://bcrypt.org/api/generate-hash.json | jq -r '.hash') || exit
	# API no longer working
	fetch https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/py311-bcrypt-3.2.2_1.pkg
	pkg install py311-bcrypt-3.2.2_1.pkg
	PASSWD=$(python3 -c "import bcrypt, sys; print(bcrypt.hashpw(sys.stdin.read().strip().encode(), bcrypt.gensalt(10)).decode())" <<< "${8}") || exit

	if [ -n "$PASSWD" ]; then
		echo "PASSWD variable set to $PASSWD, proceeding";
		fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/${3}/${1} > /dev/null 2>&1
	else
		echo "PASSWD variable is empty, trying another way" 
		curl -s -X POST --data "password=${8}&cost=10" https://bcrypt.org/api/generate-hash.json |  jq -r '.hash'> ./hash;
		env PASSWD=`cat "./hash"`
		if [ -n "$PASSWD" ]; then
			echo "PASSWD variable set to $PASSWD, proceeding";
			fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/${3}/${1} > /dev/null 2>&1
		else
			echo "PASSWD variable is empty, using config.defpass.xml"
			fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/configs/${3}/config.defpass.xml > /dev/null 2>&1
			mv config.defpass.xml config.xml;
		fi
	fi
	
	if [ -s ./config.xml ]; then
		sed -i '' -E -e 's|24.24.24.24|'$PASSWD'|g' config.xml;
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
		cp -f config.xml /usr/local/etc/config.xml
	else
		echo "config.xml doesn't exist, exiting"
		exit 1
	fi
		
	# Dowload OPNSense Bootstrap and Permit Root Remote Login
	#fetch https://raw.githubusercontent.com/opnsense/update/dddae7d70e/src/bootstrap/opnsense-bootstrap.sh.in > /dev/null 2>&1
	# https://github.com/opnsense/update?tab=readme-ov-file#opnsense-bootstrap
	fetch https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in > /dev/null 2>&1
	sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config;
	#OPNSense
	sed -i "" "s/set -e/#set -e/g" opnsense-bootstrap.sh.in
	sed -i "" "s/reboot/shutdown -r +1/g" opnsense-bootstrap.sh.in	
	
	echo "Checking if /usr/local/etc/config.xml file exists"
	if [ -f /usr/local/etc/config.xml ]; then
		echo "Starting OpnSense installation"
		sh opnsense-bootstrap.sh.in -y -r ${2};
		
		# Installing bash - This is a requirement for Azure custom Script extension to run
		pkg install -y bash
		pkg install -y os-frr
		
		# Add Azure waagent
		fetch https://github.com/Azure/WALinuxAgent/archive/refs/tags/v${9}.tar.gz
		tar -xvzf v${9}.tar.gz
		cd WALinuxAgent-${9}/
		python3 setup.py install --register-service --lnx-distro=freebsd --force
		cd ..

		# Fix waagent by replacing configuration settings
		TARGET="/usr/local/bin/python"
		# Source python version
		SOURCE="/usr/local/bin/python3.11"

		# Check if target exists
		if [ -e "$TARGET" ]; then
			# Get versions of both python binaries
			SOURCE_VERSION=$("$SOURCE" --version 2>&1)
			TARGET_VERSION=$("$TARGET" --version 2>&1)
			
			# Compare versions
			if [ "$SOURCE_VERSION" = "$TARGET_VERSION" ]; then
				echo "Symlink not needed: $TARGET already exists and points to same version ($TARGET_VERSION)"
				exit 0
			else
				echo "Warning: $TARGET exists but has different version ($TARGET_VERSION) than $SOURCE ($SOURCE_VERSION)"
				echo "Remove existing $TARGET first if you want to replace it"
				exit 1
			fi
		fi

		# If we get here, target doesn't exist, so create the symlink
		ln -s "$SOURCE" "$TARGET"
		if [ $? -eq 0 ]; then
			echo "Successfully created symlink: $TARGET -> $SOURCE"
		else
			echo "Failed to create symlink"
			exit 1
		fi
		##sed -i "" 's/command_interpreter="python"/command_interpreter="python3"/' /etc/rc.d/waagent
		##sed -i "" 's/#!\/usr\/bin\/env python/#!\/usr\/bin\/env python3/' /usr/local/sbin/waagent
		sed -i "" 's/ResourceDisk.EnableSwap=y/ResourceDisk.EnableSwap=n/' /etc/waagent.conf
		
		FOLDER="/usr/local/opnsense/service/conf/actions.d"  # Change this to your desired folder

		# Check if folder exists
		if [ -d "$FOLDER" ]; then
			echo "Folder $FOLDER exists, proceeding to create file..."
		else
			echo "Folder $FOLDER does not exist, creating it..."
			mkdir -p "$FOLDER"
		fi
		cat << 'EOF' > /usr/local/opnsense/service/conf/actions.d/waagent_service.conf
[start]
command:service
parameters:waagent start
type:script
message:starting waagent

[stop]
command:service
parameters:waagent stop
type:script
message:stopping waagent

[restart]
command:service
parameters:waagent restart
type:script
message:restarting waagent

[status]
command:service
parameters:waagent status
type:script_output
message:status waagent
EOF
		
		#Adds support to LB probe from IP 168.63.129.16
		fetch https://raw.githubusercontent.com/oleksandrmeleshchuk-epm/Azure-OpnSense/main/OpnSense/scripts/lb-conf.sh > /dev/null 2>&1
		sh ./lb-conf.sh
		# Reset WebGUI certificate
		echo #\!/bin/sh >> /usr/local/etc/rc.syshook.d/start/94-restartwebgui
		echo configctl webgui restart renew >> /usr/local/etc/rc.syshook.d/start/94-restartwebgui
		echo rm /usr/local/etc/rc.syshook.d/start/94-restartwebgui >> /usr/local/etc/rc.syshook.d/start/94-restartwebgui
		chmod +x /usr/local/etc/rc.syshook.d/start/94-restartwebgui
		
		rm -rf hash
		shutdown -r +1
	else
		echo "OpnSense installation failed, exiting"
		exit 1
	fi
else
	echo "PASSWD variable have not been set, exiting"
	exit 1
fi
