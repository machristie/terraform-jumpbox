output "vm_public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}
output "jumpbox_public_ip" {
  value = azurerm_public_ip.jumpbox_public_ip.ip_address
}
