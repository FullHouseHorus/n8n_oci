variable "tenancy_ocid" {
  description = "OCID of Oracle Cloud Tenancy"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}


variable "n8n_user" {
  description = "Username for logging in to n8n"
  type        = string
  default     = "admin"
}

variable "n8n_password" {
  description = "Password for logging in to n8n (pick a strong one)"
  type        = string
  sensitive   = true
}

variable "n8n_timezone" {
  description = "Timezone for n8n scheduled workflows (e.g. America/New_York)"
  type        = string
  default     = "America/New_York"
}
