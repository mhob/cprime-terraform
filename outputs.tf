output "bastion-vm-public-ip" {
  value = azurerm_linux_virtual_machine.lab-bastion.public_ip_address
}

output "db-server-endpoint" {
  value = azurerm_postgresql_server.lab.fqdn
}

# Add a new output so we can easily get the load balancer public IP.
output "load-balancer-public-ip" {
  value = azurerm_public_ip.lab-lb.ip_address
}
