variable "name"               { type = string }
variable "app"                { type = string }
variable "env"                { type = string }
variable "versioning" {
  type    = bool
  default = true
}
variable "lifecycle_days"     { type = number default = 365 }
variable "block_public_access"{ type = bool   default = true }
variable "server_access_logs" { type = bool   default = true }
variable "tags" {
  type    = map(string)
  default = {}
}
