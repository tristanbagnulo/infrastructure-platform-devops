variable "app" {
  description = "Application name"
  type        = string
}

variable "env" {
  description = "Environment (dev/stage/prod)"
  type        = string
}

variable "name" {
  description = "Resource name"
  type        = string
}

variable "purpose" {
  description = "Storage purpose"
  type        = string
  validation {
    condition     = contains(["file_storage", "data_lake", "backup", "static_website"], var.purpose)
    error_message = "Purpose must be one of: file_storage, data_lake, backup, static_website."
  }
}

variable "access_pattern" {
  description = "Access pattern for storage class optimization"
  type        = string
  default     = "frequent"
  validation {
    condition     = contains(["frequent", "infrequent", "archive"], var.access_pattern)
    error_message = "Access pattern must be one of: frequent, infrequent, archive."
  }
}

variable "retention_days" {
  description = "Object retention period in days"
  type        = number
  default     = 365
}

variable "versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "public_access" {
  description = "Allow public access"
  type        = bool
  default     = false
}

variable "cors_enabled" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "cross_region_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
