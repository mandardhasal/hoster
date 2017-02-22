#!/bin/sh

#configs

#path to host file  
host_file="/etc/hosts";


#if all virtual host configurations are added into a single file, give the file path 
#eg:- vhost_path="/etc/apache2/site-enabled/myvirtualhost.conf"
#eg:- vhost_path="/etc/apache2/sites-enabled/000-default.conf";

#if each virtualhost is added into a seperate file give the directory path 
#eg:- vhost_path="/etc/apache2/site-enabled/";

vhost_path="/etc/apache2/sites-enabled/";



okmsg="\033[0;32m[OK]\033[0m";

show_usage(){
	echo 
	echo "	Usage:"
	echo "		[add] [domain] [path <optional>]"
	echo ""
	echo "			#if the optional parameter 'path' is passed, a virtual host will be added"
	echo ""
	echo "		[remove] [domain]"
	echo
	exit;
}


dirpath='';
set_dirpath(){
	dirpath="$( cd -P "${1}"  && pwd )" > /dev/null 2>&1 
	if [ $? -ne 0 ]; then
		echo "path: ${1} not found"
		exit;
	fi
}

chek_wperms(){
	if [ ! -w "${1}" ]; then
		echo "Permission denied: Try running with sudo"	
		exit;
	fi
}

check_hostfile(){
	if [ ! -e $host_file ]; then
		echo "host file: $host_file does not exist"	
		exit; 
	fi
	chek_wperms $host_file
}

chk_hostexist(){
	chk_exist=$( grep "\<${1}\>" ${2} )
	if [ -z "$chk_exist" ]; then	
		return 0;
	else
		return 1;
	fi
}

append_hostfile(){	
	chk_hostexist "${1}" "$host_file"
	if [ $? -eq 0 ]; then	
		echo >> $host_file
		echo "127.0.0.1 ${1}" >> $host_file
		echo "'${1}' is successfully added to $host_file		$okmsg"
	else
		echo "'${1}' is already present in $host_file		$okmsg"
	fi
}

remove_hostfile(){
	host="${1}"; 
	chk_hostexist "$host" "$host_file"
	if [ $? -eq 0 ]; then
		echo "'$host' is not present in host file			$okmsg"
	else
		#use either one
		#awk '/^([0-9]|.)+ www.newmd.com$/{ print NR; }' /etc/hosts
		#grep -n  '^\([0-9]\|\.\)\+\swww.newmd.com$' /etc/hosts | cut -d : -f1
		line_no=`awk "/^([0-9]|.)+ $host$/{ print NR; exit; }" $host_file`
		if [ -z $line_no ]; then
			read -p "Warning: one or more alias exist with $host. Do you want to continue? (y/n) : " yn
			case $yn in
        		[Yy] ) line_no=`awk "/$host/{ print NR; }" $host_file` ; break;;
        		* ) echo "! Host file entries are not removed"; return;;
        	esac
		fi
		tmpfile='/tmp/etc_host_file';
		`sed  ${line_no}d $host_file > $tmpfile`
		`mv $tmpfile $host_file`
		echo "'$host' removed successfully from host file		$okmsg"	
	fi

}

vhost_mode='';
set_vhost_mode(){
	if [ -d $vhost_path ]; then
		vhost_mode='D';
		chek_wperms $vhost_path
	elif [ -e $vhost_path ]; then
		vhost_mode='F';
		chek_wperms $vhost_path
	fi
}	

add_vhostfile(){
	vhfile="$vhost_path/${1}.conf"
	if [ -e $vhfile ]; then
		echo "Virtual Host for '${1}' already exist 			$okmsg";
	else
		echo "#added by vhost " > $vhfile
		add_vhost ${1} $vhfile
	fi 
}

add_vhost(){
	echo "<VirtualHost *:80>\n" >> "${2}"
	echo "	ServerName ${1}\n	ServerAdmin admin@${1}\n	DocumentRoot $dirpath\n" >> "${2}"
	echo "</VirtualHost>" >> "${2}"
	echo "Virtual Host added successfully, restart apache		$okmsg"
}

remove_vhostfile(){
	vhfile="$vhost_path/${1}.conf"
	if [ ! -e $vhfile ]; then echo "'${1} is not present in Virtual host path 		$okmsg"; return; fi
	
	rm $vhfile;
	echo "Virtual Host removed successfully, restart apache	$okmsg"
}

append_vhostfile(){
	chk_hostexist "${1}" "$vhost_path"
	if [ $? -eq 0 ]; then
		echo >> $vhost_path
		echo "#added by vhost " >> $vhost_path
		add_vhost ${1} $vhost_path
		echo "'${1}' successfully added to vhost file 		$okmsg"
	else
		echo "'${1}' already exist in vhost file 			$okmsg"
	fi
}

add_host(){
	if [ -z "${1}" ]; then
		show_usage
	else
		if [ ! -z "${2}" ]; then
			set_dirpath "${2}"
			set_vhost_mode
			if [ ${vhost_mode} = "D" ]; then
				add_vhostfile "${1}" 
			elif [ ${vhost_mode} = "F" ]; then 
				append_vhostfile "${1}" 
			else 
				echo "Virtual host path not found '$vhost_path'"
				return;
			fi 
		fi
		check_hostfile
		append_hostfile "${1}"			
	fi 
}

remove_vhost(){
	hostline=`awk "/ServerName ${1}$/{print NR;exit;}" $vhost_path`

	lastline=`awk "NR>$hostline && /^<\/VirtualHost>/{print NR; exit;}" $vhost_path`
	firstline=`awk "NR<$hostline && /^<VirtualHost/{print NR;}" $vhost_path | tail -1`

	tmpfile='/tmp/tmp_vhost_file';
	`sed "${firstline},${lastline}d" $vhost_path > $tmpfile` 
	`mv $tmpfile $vhost_path`
	echo "Virtual Host removed successfully, restart apache	$okmsg"
}

remove_host(){
	if [ -z "${1}" ]; then
		show_usage
	else
		check_hostfile
		remove_hostfile "${1}"
		set_vhost_mode
		if [ ${vhost_mode} = "D" ]; then
			remove_vhostfile "${1}"
		elif [ ${vhost_mode} = "F" ]; then 
			chk_hostexist "${1}" "$vhost_path"
			if [ $? -eq 0 ]; then
				#return;
				echo "'${1}' is not present in vhost file 			$okmsg"
			else
				remove_vhost "${1}"
			fi

		fi
	fi
}


case ${1} in
	add) add_host "${2}" "${3}"
		;;
	#update) update_host "${2}" "${3}"
	#	;;
	remove) remove_host "${2}"
		;;
	*) show_usage
		;;
esac