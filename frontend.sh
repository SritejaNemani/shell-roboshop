#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m" #red
G="\e[32m" #green
Y="\e[33m" #yellow
N="\e[0m" #normal-white
SCRIPT_DIR=$PWD
#MONGODB_HOST=mongodb.nemani.online

if [ $USER_ID -ne 0 ]; then
   echo -e "$R Not root user - please run this script with root user$N" | tee -a $LOGS_FILE
   exit 1 #if we dont give this Even if there is an error the script executes the next lines as well. In order to prevent this we exit with any failure code generally 1
fi

mkdir -p $LOGS_FOLDER


VALIDATE(){
   if [ $1 -ne 0 ]; then    #here $1 -- 1st arg is $? - exit status of prev command
      echo -e "$2 $R Failure $N" | tee -a $LOGS_FILE # $2 2nd arg is Insatll nginx(package)
      exit 1 # here if it is one installation like prev screipt exiit 1 isn't required but here if we don'r exit the script will continue with next installations which may lead to problem
   else 
      echo -e "$2 $G Success $N" | tee -a $LOGS_FILE
   fi
}

echo "Disabling other versions of Nginx"
dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disabling other versions of Nginx"

echo "Enabling V1.24 of Nginx"
dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling V1.24 of Nginx"

echo "Installing Nginx"
dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

echo "Enabling Nginx"
systemctl enable nginx &>>$LOGS_FILE
VALIDATE $? "Enabling Nginx"

echo "Starting Nginx"
systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "Starting Nginx"

echo "Removing exixiting defailt HTML code"
rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "Removing exixiting  HTML code"

echo "Downloading Front-end"
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading Front-end"

echo "opening directtory and unzipping"
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "opening directtory and unzipping"

echo "Force removinf the ecisiting conf file"
rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Force removinf the ecisiting conf file"

echo "Copying our modified nginx conf filr"
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying our modified nginx conf filr"

echo "Restarting Nginx"
systemctl restart nginx
VALIDATE $? "Restarting Nginx"