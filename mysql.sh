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

echo "Installing MySQL Server"
dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL Server"

echo "Enabling MySQL Server"
systemctl enable mysqld -y &>>$LOGS_FILE
VALIDATE $? "Enabling MySQL Server"

echo "Starting MySQL Server"
systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "Starting MySQL Server"


mysql_secure_installation --set-root-pass RoboShop@1