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
variable "jumpbox_nsg_allow_ssh_address_prefixes" {
  default = [
    "143.215.0.0/16", # GT network subnet
    "216.249.91.203"  # Marcus home IP address
  ]
}
variable "vm_subnet_name" {
  default = "vm-subnet"
}
variable "vm_subnet_address_prefixes" {
  default = ["10.0.0.0/24"]
}
variable "username" {
  default = "rocky"
}
variable "jumpbox_username" {
  default = "ubuntu"
}
