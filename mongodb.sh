#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m" #red
G="\e[32m" #green
Y="\e[33m" #yellow
N="\e[0m" #normal-white

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

echo "Copying Mongo Repo"
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo Repo"

echo "Installing MongoDB Server"
dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Server"

echo "Enabling MongoDB Server"
systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB Server"

echo "Starting MongoDB Server"
systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB Server"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

echo "Restarting MongoDB Server"
systemctl restart mongod 
VALIDATE $? "Restarting MongoDB Server"