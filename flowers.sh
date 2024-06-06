#! /bin/bash

function verifyInstanceHasOutboundConnection() {
  for i in {1..10}; do
    resp=$(curl -m 5 -I http://google.com)
    if [ "$resp" ]; then
      echo "Instance has outbound connection"
      return
    fi
    echo "Instance does not have outbound connection retrying in 5 seconds"
    sleep 5
  done
}

function installGit() {
  echo "UPDATING THE SYSTEM"
  yum update -y
  echo "INSTALLING GIT"
  yum install git -y
}

function cloneFlowersRepo() {
  echo "CLONING THE FLOWERS REPO"
  git clone https://github.com/yushni/flowers.git
}

function runApp() {
  echo "ADD PERMISSIONS TO THE FLOWERS DIRECTORY"
  chmod 777 flowers/

  echo "ENTERING THE FLOWERS DIRECTORY"
  cd flowers || return

  echo "Retrieving token from metadata service"
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
  REGION="$(echo "$AVAILABILITY_ZONE" | sed 's/[a-z]$//')"

  echo "RETRIEVING SMTP PARAMETERS"
  SMTP_PASSWORD=$(aws ssm get-parameter --name "/smtp/password" --region $REGION --with-decryption --query "Parameter.Value" | sed 's/"//g')
  SMTP_USERNAME=$(aws ssm get-parameter --name "/smtp/username" --region $REGION --with-decryption --query "Parameter.Value" | sed 's/"//g')
  SMTP_RECIPIENT=$(aws ssm get-parameter --name "/smtp/recipient" --region $REGION --with-decryption --query "Parameter.Value" | sed 's/"//g')

  echo "RUN THE APP"
  SMTP_RECIPIENT=$SMTP_RECIPIENT SMTP_PASSWORD=$SMTP_PASSWORD SMTP_USERNAME=$SMTP_USERNAME ./app &
}

function main() {
  verifyInstanceHasOutboundConnection
  installGit
  cloneFlowersRepo
  runApp

  echo "END USER DATA"
}

main
