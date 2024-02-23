# Environment, for example "prod" or "test"
variable "environment" {
    type = string
    default = "test"
}

# The name of your new service, for example "backstage"
variable "service_name" {
    type = string
    default = "backstageerni"
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

# Now comes a bunch of the properties we mentioned when creating the Github application.
/*
variable "github_backstage_appid" {
    type = string
    default = "812384"
}

variable "github_backstage_webhookUrl" {
    type = string
}

variable "github_backstage_clientId" {
    type = string
}

variable "github_backstage_clientSecret" {
    type = string
}

variable "github_backstage_webhookSecret" {
    type = string
}

# If you're running this in Terraform Cloud, just replace all line breaks in the PEM file with \n and chain it all together to one long line.
variable "github_backstage_privateKey" {
    type = string
}*/
