variable "region" {
  type = string
}

variable "vm_password" {
  description = "6-20 characters. At least 1 lower, 1 cap, 1 number, 1 special char."
  type        = string
  sensitive   = true
}

variable "db_storage" {
  type    = number
  default = 5120

  validation {
    condition     = var.db_storage >= 5120 && var.db_storage % 1024 == 0
    error_message = "Minimum db storage is 5120 and must be multiple of 1024."
  }
}

# Lab4.6: Add a new variable to accept additional tags to set on our resources.
variable "tags" {
  type    = map(string)
  default = {}
}

# Lab 4.6: Add two more variables:
# - `node_count` of type number with default as null
# - `load_level` of type string with default as empty string
variable "node_count" {
  type    = number
  default = null
}
variable "load_level" {
  type    = string
  default = ""
}
