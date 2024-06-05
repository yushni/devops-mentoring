#!/bin/bash

function enableApiTables() {
  yum install iptables-services -y
  systemctl enable iptables
  systemctl start iptables
}

function enableIpForwarding() {
  echo net.ipv4.ip_forward=1 >/etc/sysctl.d/custom-ip-forwarding.conf
  sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf
}

function configureNAT() {
  /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  /sbin/iptables -F FORWARD
  service iptables save
}

function replaceRouteAndDisableDestinationCheck() {
  echo "Retrieving token from metadata service"
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  echo "Retrieving instance ID from metadata service"
  INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

  AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
  REGION="$(echo \"$AVAILABILITY_ZONE\" | sed 's/[a-z]$//')"

  aws ec2 replace-route --route-table-id rtb-082e1eca00c342e59 --destination-cidr-block 0.0.0.0/0 --instance-id $INSTANCE_ID --region $REGION
  aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --no-source-dest-check --region $REGION
}

function main() {
  yum update -y

  echo "Enabling API tables..."
  enableApiTables
  echo "API tables enabled."
  echo "Enabling IP forwarding..."
  enableIpForwarding
  echo "IP forwarding enabled."
  echo "Configuring NAT..."
  configureNAT
  echo "NAT configured."
  echo "Replacing route and disabling destination check..."
  replaceRouteAndDisableDestinationCheck
  echo "Route replaced and destination check disabled."

  echo "END USER DATA"

}

main
