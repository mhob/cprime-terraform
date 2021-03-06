terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.40, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 1.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-course-backend"
    container_name       = "tfstate"
    key                  = "cprime.terraform.labs.tfstate"
    storage_account_name = "aztfcoursebackend05"
  }
  required_version = "~> 1.0.0"
}

provider "azurerm" {
  features {}
  # Below may be needed for lab environment
  skip_provider_registration = true
}

provider "azuread" {}

locals {
  region = var.region
  # Lab4.6: merge the `tags` input variable and the existing tag map
  common_tags = merge(var.tags, {
    Environment = "Lab"
    Project     = "AZTF Training"
  })
  # Lab4.6: add size specs
  size_spec = {
    low = {
      cluster_size = 1
    },
    medium = {
      cluster_size = 2
    },
    high = {
      cluster_size = 3
    }
  }
  # Lab4.6: determine cluster_size according to the following criteria:
  # - Use input variable node_count if it is not null
  # - Otherwise use the input variable load_level to lookup a cluster_size value
  #   from the size_spec map
  # - If both node_count and load_level input variables are undefined, then the
  #   default cluster size should be 1
  cluster_size = try(coalesce(var.node_count, lookup(local.size_spec, var.load_level).cluster_size), 1)
  # lab4.5: map of security group rules
  sg_rules = {
    HTTP-Access = {
      priority               = 100,
      direction              = "Inbound",
      access                 = "Allow",
      protocol               = "Tcp",
      destination_port_range = 80
    },
    SSH-Access = {
      priority               = 110,
      direction              = "Inbound",
      access                 = "Allow",
      protocol               = "Tcp",
      destination_port_range = 22
    }
  }
}

resource "azurerm_resource_group" "lab" {
  name     = "aztf-labs-rg"
  location = local.region
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "lab" {
  name                = "aztf-labs-vnet"
  location            = local.region
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "lab-public" {
  name                 = "aztf-labs-subnet-public"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "lab-private" {
  name                 = "aztf-labs-subnet-private"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab-public" {
  name                = "aztf-labs-public-sg"
  location            = local.region
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                         = "SSH-Access"
    priority                     = 110
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "22"
    source_address_prefix        = "*"
    destination_address_prefixes = azurerm_subnet.lab-public.address_prefixes
  }
}

# Add a new security group for the private subnet that will allow traffic to
# ports 80 and 22 on our new virtual machines.
resource "azurerm_network_security_group" "lab-private" {
  name                = "aztf-labs-private-sg"
  location            = local.region
  resource_group_name = azurerm_resource_group.lab.name
  # lab4.5: replace the security group rules in the private network security
  # group with a dynamic block
  dynamic "security_rule" {
    for_each = local.sg_rules
    content {
      name                         = security_rule.key
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = "*"
      destination_port_range       = security_rule.value.destination_port_range
      source_address_prefix        = "*"
      destination_address_prefixes = azurerm_subnet.lab-private.address_prefixes
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "lab-public" {
  subnet_id                 = azurerm_subnet.lab-public.id
  network_security_group_id = azurerm_network_security_group.lab-public.id
}

# Associate the new security group to the private subnet.
resource "azurerm_subnet_network_security_group_association" "lab-private" {
  subnet_id                 = azurerm_subnet.lab-private.id
  network_security_group_id = azurerm_network_security_group.lab-private.id
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}
