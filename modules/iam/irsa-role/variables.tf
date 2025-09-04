variable "app"        { type = string }
variable "env"        { type = string }
variable "namespace"  { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string } # without https://
variable "grants" {
  description = "Resource ARNs to grant access to, grouped by service"
  type = object({
    s3           = optional(list(string), [])
    sqs          = optional(list(string), [])
    dynamodb     = optional(list(string), [])
    rds_secrets  = optional(list(string), [])  # RDS database secrets
    secrets      = optional(list(string), [])  # Application secrets
  })
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
