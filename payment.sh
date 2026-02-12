#!/bin/bash


USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m" #red
G="\e[32m" #green
Y="\e[33m" #yellow
N="\e[0m" #normal-white
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.nemani.online

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


echo "Installing Python"
dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing Python"

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

echo "Downloading payment code"
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading payment code"

echo "Opening app Directory"
cd /app 
VALIDATE $? "Opening app Directory"

echo "Removing all existing files in App directory"
rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing all existing files in App directory"

echo "Unzipping the downloaded code"
unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the downloaded code"

cd /app 

echo "Installing Dependencies"
pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing Dependencies"

echo "Creating Systemctl Service"
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
VALIDATE $? "Creating Systemctl Service"

echo "Loading the Service"
systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Loading the Service"

echo "Enabling Payment Server"
systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "Enabling Payment Server"

echo "Starting Payment Server"
systemctl start payment &>>$LOGS_FILE
VALIDATE $? "Starting Payment Server"

