#!/bin/bash

LOG_FILE="/tmp/jinstall.log"

# Check for root user
if [ $(id -u) -ne 0 ]; then
    echo -e "You should perform this as root user"
    exit 1
fi

# Function to check status
Stat() {
    if [ $1 -ne 0 ]; then
        echo "Installation Failed : Check log $LOG_FILE"
        exit 2
    fi
}

# Step 1: Install Java (OpenJDK 17) and required packages
echo "[INFO] Installing dependencies..." | tee -a $LOG_FILE
yum install -y fontconfig java-17-openjdk java-17-openjdk-devel wget &>$LOG_FILE
Stat $?

# Step 2: Add Jenkins repo (using curl to avoid TLS issue)
curl -k -L https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo &>>$LOG_FILE
Stat $?

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key &>>$LOG_FILE
Stat $?

# Step 3: Install Jenkins
echo "[INFO] Installing Jenkins..." | tee -a $LOG_FILE
yum install -y jenkins --nogpgcheck &>>$LOG_FILE
Stat $?

# Step 4: Enable and Start Jenkins Service
echo "[INFO] Enabling and starting Jenkins service..." | tee -a $LOG_FILE
systemctl enable jenkins &>>$LOG_FILE
Stat $?

systemctl start jenkins &>>$LOG_FILE
Stat $?

# Step 5: Setup SSH config for Jenkins (optional, for GitHub access)
mkdir -p /var/lib/jenkins/.ssh
echo 'Host *
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no' >/var/lib/jenkins/.ssh/config
chown jenkins:jenkins /var/lib/jenkins/.ssh -R
chmod 400 /var/lib/jenkins/.ssh/config

# Step 6: Print success and initial admin password
echo -e "\e[32m INSTALLATION SUCCESSFUL \e[0m"
echo "[INFO] Access Jenkins at: http://<server-ip>:8080"
echo "[INFO] Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Start Jenkins and check the password later."