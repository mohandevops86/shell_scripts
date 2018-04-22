#!/bin/bash


#### Variables
MODJK_URL='http://redrockdigimark.com/apachemirror/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.42-src.tar.gz'
MODJK_TAR_FILE="/opt/$(echo $MODJK_URL | awk -F / '{print $NF}')"
MODJK_DIR=$(echo $MODJK_TAR_FILE | sed -e 's/.tar.gz//' )

TOMCAT_URL='https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.29/bin/apache-tomcat-8.5.29.tar.gz'
TOMCAT_TAR_FILE="/opt/$(echo $TOMCAT_URL | awk -F / '{print $NF}')"
TOMCAT_DIR=$(echo $TOMCAT_TAR_FILE | sed -e 's/.tar.gz//')

MARIADB_CONN_URL='https://github.com/cit-latex/stack/raw/master/mysql-connector-java-5.1.40.jar'
MARIADB_CONN_FILE=$(echo $MARIADB_CONN_URL | awk -F / '{print $NF}')
STUDENTAPP_WAR_URL='https://github.com/cit-latex/stack/raw/master/student.war'

LOG=/tmp/stack.log.$$
##### Functions
HEAD_F() {
	echo -e "** \e[35;4m$1\e[0m"	
}

Print() {
	echo -n "	-> $1 - "
}

Stat() {
	if [ $1 == SKIP ]; then 
		echo -e "\e[34mSKIPPING\e[0m"
	elif [ $1 -eq 0 ]; then 
		echo -e "\e[32mSUCCESS\e[0m"
	else
		echo -e "\e[31mFAILURE\e[0m"
		exit 1
	fi
}

WEB_F() {
	HEAD_F "Configuring Web Service"

	Print "Installing Web Server"
	yum install httpd httpd-devel gcc -y &>>$LOG
	Stat $?
	Print "Downloading Mod_JK Package"
	if [ -f $MODJK_TAR_FILE ]; then
		Stat SKIP
	else
		wget $MODJK_URL -O $MODJK_TAR_FILE &>>$LOG
		Stat $?
	fi
	Print "Extracting Mod_JK Package"
	if [ -d $MODJK_DIR ]; then 
		Stat SKIP 
	else
		cd /opt
		tar xf $MODJK_TAR_FILE
		Stat $?
	fi

	Print "Compiling Mod_JK"
	if [ -f /etc/httpd/modules/mod_jk.so ] ; then 
		Stat SKIP 
	else
		cd $MODJK_DIR/native
		./configure --with-apxs=/usr/bin/apxs &>>$LOG && make &>>$LOG && make install &>>$LOG
		Stat $?
	fi
	echo 'worker.list=tomcatA
### Set properties
worker.tomcatA.type=ajp13
worker.tomcatA.host=localhost
worker.tomcatA.port=8009' >/etc/httpd/conf.d/worker.properties

	echo 'LoadModule jk_module modules/mod_jk.so
JkWorkersFile conf.d/worker.properties
JkMount /student tomcatA
JkMount /student/* tomcatA' >/etc/httpd/conf.d/mod_jk.conf

	Print "Starting Web Service"
	systemctl enable httpd &>>$LOG
	systemctl restart httpd &>>$LOG 
	Stat $?
}

APP_F() {

	echo
	HEAD_F "Configuring App Service"

	Print "Installing JAVA"
	yum install java -y  &>>$LOG
	Stat $?

	Print "Downloading Tomcat"
	if [ -f $TOMCAT_TAR_FILE ];then 
		Stat SKIP 
	else
		wget $TOMCAT_URL -O $TOMCAT_TAR_FILE &>>$LOG
		Stat $?
	fi

	Print "Extracting Tomcat"
	if [ -d $TOMCAT_DIR ]; then 
		Stat SKIP 
	else
		cd /opt
		tar xf $TOMCAT_TAR_FILE
		Stat $?
	fi

	rm -rf $TOMCAT_DIR/webapps/*

	Print "Downloading MariaDB Connector"
	if [ -f $TOMCAT_DIR/lib/$MARIADB_CONN_FILE ]; then 
		Stat SKIP 
	else
		wget $MARIADB_CONN_URL -O $TOMCAT_DIR/lib/$MARIADB_CONN_FILE &>>$LOG
		Stat $?
	fi 

	Print "Downloading Student Webapp"
	wget $STUDENTAPP_WAR_URL -O $TOMCAT_DIR/webapps/student.war &>>$LOG
	Stat $?

	sed -i -e '/TestDB/ d' -e '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/>' $TOMCAT_DIR/conf/context.xml

	#### Checking my tomcat is running or not
	ps -ef | grep tomcat | grep -v grep &>>$LOG
	if [ $? -eq 0 ]; then 
		Print "Restarting Tomcat"
		sh $TOMCAT_DIR/bin/shutdown.sh &>>$LOG
		i=12
		while [ $i -gt 0 ]; do 
			ps -ef | grep tomcat | grep -v grep &>>$LOG
			if [ $? -eq 0 ]; then
				sleep 5
			else
				break
			fi
			sleep 5
			i=$(($i-1))
		done
		ps -ef | grep tomcat | grep -v grep &>>$LOG
		if [ $? -eq 0 ] ; then 
			Stat 1
		fi
		sh $TOMCAT_DIR/bin/startup.sh  &>>$LOG
		Stat $?
	else
		Print "Starting Tomcat" 
		sh $TOMCAT_DIR/bin/startup.sh  &>>$LOG
		Stat $?
	fi
}

DB_F() {
	echo
	HEAD_F "Configuring DB Service"
	Print "Installing MariaDB"
	yum install mariadb-server -y &>>$LOG
	Stat $?

	Print "Starting Service"
	systemctl enable mariadb &>>$LOG
	systemctl restart mariadb &>>$LOG
	Stat $?

	Print "Configuring DB"
	echo "create database if not exists studentapp;
use studentapp;
CREATE TABLE if not exists Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
  student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);
grant all privileges on studentapp.* to 'student'@'localhost' identified by 'student@1';
flush privileges;" >/tmp/student.sql 
	mysql < /tmp/student.sql &>/tmp/mysql.log 
	Stat $?
}

ALL_F() {
	WEB_F
	APP_F
	DB_F
}

##### Main Script
if [ "$USER" != root ]; then 
	echo "You should be a root user to perform this script"
	exit 1
fi

if [ -z "$1" ]; then 
	read -p 'Which Service you would like to install[WEB|APP|DB|ALL] : ' SETUP
	if [ -z "$SETUP" ]; then 
		SETUP=ALL
	fi
else
	SETUP=$1
fi

SETUP=$(echo $SETUP | tr [a-z] [A-Z])
case $SETUP in 
	WEB|web) 
		WEB_F
		;;
	APP|app)
		APP_F
		;;
	DB|db)
		DB_F
		;;
	ALL|all)
		ALL_F
		;;
	*) 
		echo "Allowed values are WEB|APP|DB|ALL ... Try Again .."
		exit 1
esac
