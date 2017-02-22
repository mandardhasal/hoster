# hoster
A simple utility to add host to hosts file and also add a virtual host for apache web server.

##Setup
Download hoster.sh and thats it.

##Usage
```
$ cd downloaded_directory
$ ./hoster.sh
```

##Commands
```
$ ./hoster.sh add www.example.com #this will just create a host record in hosts file.

$ ./hoster.sh add www.example.com path-to-project-directory #this will create a host record as well as a virtual host record for apache.

$ ./hoster.sh remove www.example.com #this will remove the record
```

##Configs
Edit hoster.sh and add paths for hosts and virtual hosts
If either single file is used for all virtual host or if seperate files are used for each virtual host, both is supported 
```
#path to host file  
host_file="/etc/hosts";


#if all virtual host configurations are added into a single file, give the file path 
#eg:- vhost_path="/etc/apache2/site-enabled/myvirtualhost.conf"
#eg:- vhost_path="/etc/apache2/sites-enabled/000-default.conf";

#if each virtualhost is added into a seperate file give the directory path 
#eg:- vhost_path="/etc/apache2/site-enabled/";

vhost_path="/etc/apache2/sites-enabled/";

```