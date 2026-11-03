output "core_public_ip" {
  description = "Elastic IP of the core server (use as WireGuard Endpoint)"
  value       = aws_eip.core.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.project_name}-key.pem ubuntu@${aws_eip.core.public_ip}"
}

output "wireguard_home_config" {
  description = "Paste into /etc/wireguard/wg0.conf at home (replace the placeholders)"
  value       = <<EOT
[Interface]
Address = ${var.wg_home_address}/24
PrivateKey = <HOME_PRIVATE_KEY>
MTU = 1380

[Peer]
PublicKey = <AWS_PUBLIC_KEY>
Endpoint = ${aws_eip.core.public_ip}:51820
AllowedIPs = 10.200.0.0/24
PersistentKeepalive = 25
EOT
}

output "webui_url" {
  description = "Open5GS WebUI over the VPN (login admin / 1423)"
  value       = "http://${var.wg_aws_address}:9999"
}