#!/bin/bash

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

function installNginx() {
  echo "Trying yum install"
  yum update -y
  amazon-linux-extras install nginx1 -y
  echo "Nginx installed"
}

function retrieveAndWriteTokenToNginxIndexFile() {
  echo "Retrieving token from metadata service"
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  echo "Retrieving local IP address from metadata service"
  LOCALIP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

  echo "Writing local IP address to index.html"
  echo $LOCALIP >/usr/share/nginx/html/index.html
}

function startNginx() {
  echo "Starting Nginx"
  systemctl start nginx
}

function main() {
  verifyInstanceHasOutboundConnection
  installNginx
  retrieveAndWriteTokenToNginxIndexFile
  startNginx

  echo "END USER DATA"
}

main
