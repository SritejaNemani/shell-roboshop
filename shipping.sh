#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m" #red
G="\e[32m" #green
Y="\e[33m" #yellow
N="\e[0m" #normal-white
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.nemani.online

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

echo "Installing Maven"
dnf install maven -y &>>$LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e " Roboshop user already exists - $Y skipping to create new user again$N" 
else
    echo "Creating Sysytem User"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating Sysytem User"
fi

echo "Creating App Directory"
mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating App Directory"

echo "Downloading shipping code"
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading shipping code"

echo "Opening app Directory"
cd /app 
VALIDATE $? "Opening app Directory"

echo "Removing all existing files in App directory"
rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing all existing files in App directory"

echo "Unzipping the downloaded code"
unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the downloaded code"

cd /app 

echo "Installing and building Shipping"
mvn clean package &>>$LOGS_FILE
VALIDATE $? "Installing and building Shipping"

echo "Moving and Remnaming Shipping"
mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Moving and Remnaming Shipping"


echo "Creating Systemctl Service"
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE
VALIDATE $? "Creating Systemctl Service"

echo "Loading the Service"
systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Loading the Service"

echo "Enabling Shipping Server"
systemctl enable shipping &>>$LOGS_FILE
VALIDATE $? "Enabling Shipping Server"

echo "Starting Shipping Server"
systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "Starting Shipping Server"

echo "Installing MySQL client"
dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOGS_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE

echo "Restarting Shipping Server"
systemctl restart shipping
VALIDATE $? "Restarting Shipping Server"