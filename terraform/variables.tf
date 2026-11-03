variable "aws_region" {
  description = "AWS region (the AMI ID below is specific to this region)"
  type        = string
  default     = "eu-north-1"
}

variable "admin_cidr" {
  description = "Optional: one address allowed to SSH publicly, e.g. \"203.0.113.5/32\". Leave empty to use SSH only through the VPN."
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "Ubuntu Server 24.04 LTS (x86_64) AMI ID from the EC2 launch wizard"
  type        = string
  default     = "ami-0fd9576cca965bd19"
}

variable "instance_type" {
  description = "EC2 instance type (m7i-flex.large is free tier eligible: 2 vCPU, 8 GiB)"
  type        = string
  default     = "m7i-flex.large"
}

variable "disk_size_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 40
}

variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "open5gs-lab"
}

variable "aws_wg_private_key" {
  description = "WireGuard private key for the AWS side"
  type        = string
  sensitive   = true
}

variable "home_wg_public_key" {
  description = "WireGuard public key of your home machine"
  type        = string
}

variable "wg_aws_address" {
  description = "WireGuard IP of the AWS side"
  type        = string
  default     = "10.200.0.1"
}

variable "wg_home_address" {
  description = "WireGuard IP of the home side"
  type        = string
  default     = "10.200.0.2"
}

variable "mcc" {
  type    = string
  default = "001"
}

variable "mnc" {
  type    = string
  default = "01"
}