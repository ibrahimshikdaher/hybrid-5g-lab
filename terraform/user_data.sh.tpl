#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

# ---- Base packages ----
apt-get update
apt-get install -y ca-certificates curl git wireguard iptables tcpdump net-tools

# ---- SCTP kernel module (needed by the AMF container for N2) ----
# The versioned linux-modules-extra package is not always published for the
# running AWS kernel, so try alternatives and never abort the script over it.
apt-get install -y "linux-modules-extra-$(uname -r)" \
  || apt-get install -y linux-modules-extra-aws \
  || echo "WARNING: could not install linux-modules-extra, continuing"

# ---- Kernel settings ----
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-forward.conf
sysctl --system
modprobe sctp || echo "WARNING: sctp module not available"
echo sctp > /etc/modules-load.d/sctp.conf

# ---- Docker ----
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu

# ---- WireGuard ----
umask 077
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = ${wg_aws_address}/24
ListenPort = 51820
PrivateKey = ${wg_private_key}
MTU = 1380

[Peer]
PublicKey = ${wg_home_pubkey}
AllowedIPs = ${wg_home_address}/32
EOF

systemctl enable --now wg-quick@wg0

# ---- Open5GS docker deployment ----
cd /home/ubuntu
git clone https://github.com/herlesupreeth/docker_open5gs
chown -R ubuntu:ubuntu docker_open5gs
cd docker_open5gs

# Advertise the WireGuard address so the gNB at home can reach AMF and UPF
sed -i "s/^DOCKER_HOST_IP=.*/DOCKER_HOST_IP=${wg_aws_address}/" .env
sed -i "s/^MCC=.*/MCC=${mcc}/" .env
sed -i "s/^MNC=.*/MNC=${mnc}/" .env

# The gNB runs on another host, so the UPF must advertise the VPN address too
if grep -q '^UPF_ADVERTISE_IP=' .env; then
  sed -i "s/^UPF_ADVERTISE_IP=.*/UPF_ADVERTISE_IP=${wg_aws_address}/" .env
else
  echo "UPF_ADVERTISE_IP=${wg_aws_address}" >> .env
fi

# Publish N2 (SCTP) and N3 (GTP-U) so the remote gNB can reach AMF and UPF.
# An override file avoids editing sa-deploy.yaml. The security group keeps
# these ports closed to the internet; they are only reachable through WireGuard.
cat > ports-override.yaml <<'EOF'
services:
  amf:
    ports:
      - "38412:38412/sctp"
  upf:
    ports:
      - "2152:2152/udp"
EOF

# Build images (the compose files live in the repo root, not in srsran/)
cd base && docker build --no-cache --force-rm -t docker_open5gs . && cd ..
cd ims_base && docker build --no-cache --force-rm -t docker_kamailio . && cd ..

set -a
source .env
set +a

docker compose -f sa-deploy.yaml -f ports-override.yaml build

# Start the 5G core
docker compose -f sa-deploy.yaml -f ports-override.yaml up -d

chown -R ubuntu:ubuntu /home/ubuntu/docker_open5gs
touch /home/ubuntu/DEPLOY_DONE