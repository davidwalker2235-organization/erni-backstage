# Environment, for example "prod" or "test"
variable "environment" {
    type = string
    default = "prod"
}

# The name of your new service, for example "backstage"
variable "service_name" {
    type = string
    default = "ernibackstage"
}

# Change this to match whatever suits you best
variable "location" {
    type = string
    default = "West Europe"
}

# An admin password for your database
variable "db_admin_password" {
    type = string
    default = "Dacarma@9211"
}

variable "db_admin_username" {
    type = string
    default = "backstage"
}

variable "github_organization" {
    type = string
    default = "davidwalker2235-organization"
}

variable "github_backstage_appid" {
    type = string
    default = "828233"
}

variable "github_backstage_clientId" {
    type = string
    default = "Iv1.070a80f1762cab18"
}
