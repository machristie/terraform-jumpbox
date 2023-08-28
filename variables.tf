variable "resource_group_name" {
  default = "jumpbox-demo-rg"
}
variable "location" {
  default = "eastus"
}
variable "vnet_name" {
  default = "jumpbox-demo-vnet"
}
variable "vnet_address_space" {
  default = ["10.0.0.0/16"]
}
variable "jumpbox_subnet_name" {
  default = "jumpbox-subnet"
}
variable "jumpbox_subnet_address_prefixes" {
  default = ["10.0.1.0/24"]
}
variable "vm_subnet_name" {
  default = "vm-subnet"
}
variable "vm_subnet_address_prefixes" {
  default = ["10.0.0.0/24"]
}
variable "vm_public_ip_name" {
  default = "vm-public-ip"
}
variable "username" {
  default = "rocky"
}
variable "jumpbox_username" {
  default = "ubuntu"
}
