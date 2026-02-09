#!/bin/bash
: '

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

echo "Disabling other versions of Nodejs"
dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling other versions of Nodejs"

echo "Enabling V.20 of NodeJS"
dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling V.20 of NodeJS"

echo "Installing NodeJS"
dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS"

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

echo "Downloading cart code"
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading cart code"

echo "Opening app Directory"
cd /app 
VALIDATE $? "Opening app Directory"

echo "Removing all existing files in App directory"
rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing all existing files in App directory"

echo "Unzipping the downloaded code"
unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the downloaded code"

cd /app 

echo "Installing Dependencies"
npm install &>>$LOGS_FILE
VALIDATE $? "Installing Dependencies"

echo "Creating Systemctl Service"
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOGS_FILE
VALIDATE $? "Creating Systemctl Service"

echo "Loading the Service"
systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Loading the Service"

echo "Enabling Cart Server"
systemctl enable cart &>>$LOGS_FILE
VALIDATE $? "Enabling Cart Server"

echo "Starting Cart Server"
systemctl start cart &>>$LOGS_FILE
VALIDATE $? "Starting Cart Server"

'

#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.nemani.online

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling NodeJS Default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install NodeJS"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading cart code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "Uzip cart code"

npm install  &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable cart  &>>$LOGS_FILE
systemctl start cart
VALIDATE $? "Starting and enabling cart"