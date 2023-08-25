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
