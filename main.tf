terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.89.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.12.0"
    }
    github = {
      source = "integrations/github"
      version = "4.19.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

provider "github" {
  owner = "davidwalker2235-organization" # Insert your own org name here
  #app_auth { }
}

# I use "abcd" as my "company name" here as an example, substitute for anything you want.
# Combining this name_prefix with resource type in names later on enforces good naming practices for the Azure resources.

locals {
  custom_domain = "${var.service_name}-${var.environment}.azurewebsites.net"
  name_prefix = "${var.environment}${var.service_name}"
  app_service_ip_address = distinct(split(",", azurerm_app_service.backstage_app.outbound_ip_addresses))
}

data "azurerm_client_config" "current" { }

resource "azurerm_resource_group" "backstage_rg" {
  name     = "${local.name_prefix}rg"
  location = var.location
}

resource "azuread_application" "backstage_application" {
  display_name = "${local.name_prefix}service"

  web {
    redirect_uris = [
      "https://${local.custom_domain}/api/auth/microsoft/handler/frame"
    ]
  }
}

resource "azuread_service_principal" "service_principal" {
  application_id = azuread_application.backstage_application.application_id
}

resource "azuread_application_password" "backstage_app_password" {
  application_object_id = azuread_application.backstage_application.object_id
  end_date              = "2099-01-01T01:02:03Z"
}

resource "azurerm_storage_account" "techdocs_storage" {
  name                     = "${local.name_prefix}storage"
  resource_group_name      = azurerm_resource_group.backstage_rg.name
  location                 = azurerm_resource_group.backstage_rg.location
  allow_blob_public_access = false
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "techdocs_storage_container" {
  name                  = "${local.name_prefix}techdocs"
  storage_account_name  = azurerm_storage_account.techdocs_storage.name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "service_principal_storage_access" {
  scope                = azurerm_storage_account.techdocs_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.service_principal.object_id
}

resource "azurerm_application_insights" "app_insights" {
  name                = "${local.name_prefix}appi"
  location            = azurerm_resource_group.backstage_rg.location
  resource_group_name = azurerm_resource_group.backstage_rg.name
  application_type    = "other"
}

resource "azurerm_app_service_plan" "backstage_app_plan" {
  name                = "${local.name_prefix}plan"
  location            = azurerm_resource_group.backstage_rg.location
  resource_group_name = azurerm_resource_group.backstage_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_postgresql_server" "backstage_postgresql" {
  name                = "${local.name_prefix}psql"
  location            = azurerm_resource_group.backstage_rg.location
  resource_group_name = azurerm_resource_group.backstage_rg.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  version                      = "11"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "backstage_postgresql_database" {
  name                = "docs"
  resource_group_name = azurerm_resource_group.backstage_rg.name
  server_name         = azurerm_postgresql_server.backstage_postgresql.name
  charset             = "UTF8"
  collation           = "en-US"
}

resource "azurerm_app_service" "backstage_app" {
  name                = "${local.name_prefix}app"
  location            = azurerm_resource_group.backstage_rg.location
  resource_group_name = azurerm_resource_group.backstage_rg.name
  app_service_plan_id = azurerm_app_service_plan.backstage_app_plan.id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "AZURE_CLIENT_ID" = azuread_application.backstage_application.application_id
    "AZURE_CLIENT_SECRET" = azuread_application_password.backstage_app_password.value
    "AZURE_TENANT_ID" = data.azurerm_client_config.current.tenant_id
    "POSTGRES_HOST" = azurerm_postgresql_server.backstage_postgresql.fqdn
    "POSTGRES_PORT" = 5432
    "POSTGRES_USER" = "${var.db_admin_username}@${azurerm_postgresql_server.backstage_postgresql.fqdn}"
    "POSTGRES_PASSWORD" = var.db_admin_password
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
    "DOCKER_REGISTRY_SERVER_USERNAME" = azuread_application.backstage_application.application_id
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azuread_application_password.backstage_app_password.value
    "CUSTOM_DOMAIN" = local.custom_domain
    "TECHDOCS_CONTAINER_NAME" = azurerm_storage_container.techdocs_storage_container.name
    "TECHDOCS_STORAGE_ACCOUNT" = azurerm_storage_account.techdocs_storage.name
  }
}

resource "azurerm_role_assignment" "app_service_contributor_role_assignment" {
  scope                = azurerm_app_service.backstage_app.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.service_principal.object_id
}

resource "azuread_application" "container_registry_contributor" {
  display_name = "${local.name_prefix}crcservice"
}

resource "azuread_service_principal" "cr_contributor_service_principal" {
  application_id = azuread_application.container_registry_contributor.application_id
  tags           = ["container registry", "docker", "github"]
}

resource "azuread_application_password" "cr_contributor_service_principal_password" {
  application_object_id = azuread_application.container_registry_contributor.object_id
  end_date              = "2099-02-01T01:02:03Z"
}

resource "azurerm_container_registry" "acr" {
  name                = "${local.name_prefix}acr"
  resource_group_name = azurerm_resource_group.backstage_rg.name
  location            = azurerm_resource_group.backstage_rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "container_registry_contributor_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.cr_contributor_service_principal.object_id
}

resource "azurerm_role_assignment" "backstage_app_service_principal_acr_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.service_principal.id
}

resource "azurerm_role_assignment" "backstage_app_service_principal_acr_acrpull_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.service_principal.id
}

resource "azurerm_role_assignment" "backstage_service_principal_acr_acrpull_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.service_principal.id
}

resource "github_actions_organization_secret" "registry_login_server" {
  secret_name     = "REGISTRY_LOGIN_SERVER"
  visibility      = "private"
  plaintext_value = azurerm_container_registry.acr.login_server
}

resource "github_actions_organization_secret" "registry_username" {
  secret_name     = "REGISTRY_USERNAME"
  visibility      = "private"
  plaintext_value = azuread_service_principal.cr_contributor_service_principal.application_id
}

resource "github_actions_organization_secret" "registry_password" {
  secret_name     = "REGISTRY_PASSWORD"
  visibility      = "private"
  plaintext_value = azuread_application_password.cr_contributor_service_principal_password.value
}

resource "github_actions_secret" "app_name" {
  repository       = "your-repository-name"
  secret_name      = "APP_NAME"
  plaintext_value  = azurerm_app_service.backstage_app.name
}

resource "github_actions_organization_secret" "github_techdocs_container_name" {
  visibility       = "private"
  secret_name      = "TECHDOCS_CONTAINER_NAME"
  plaintext_value  = azurerm_storage_container.techdocs_storage_container.name
}

resource "github_actions_organization_secret" "github_techdocs_storage_account_name" {
  visibility       = "private"
  secret_name      = "TECHDOCS_STORAGE_ACCOUNT"
  plaintext_value  = azurerm_storage_account.techdocs_storage.name
}

resource "github_actions_organization_secret" "github_azure_subscription_id" {
  visibility       = "private"
  secret_name      = "AZURE_SUBSCRIPTION_ID"
  plaintext_value  = data.azurerm_client_config.current.subscription_id
}

resource "github_actions_organization_secret" "github_azure_tenant_id" {
  visibility       = "private"
  secret_name      = "AZURE_TENANT_ID"
  plaintext_value  = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_organization_secret" "github_azure_client_id" {
  visibility       = "private"
  secret_name      = "AZURE_CLIENT_ID"
  plaintext_value  = azuread_service_principal.service_principal.application_id
}

resource "github_actions_organization_secret" "github_azure_client_secret" {
  visibility       = "private"
  secret_name      = "AZURE_CLIENT_SECRET"
  plaintext_value  = azuread_application_password.backstage_app_password.value
}

resource "github_actions_secret" "azure_credentials" {
  repository       = "your-repository-name"
  secret_name      = "AZURE_CREDENTIALS"
  plaintext_value  = jsonencode({
    "clientId" = azuread_service_principal.service_principal.application_id
    "clientSecret" = azuread_application_password.backstage_app_password.value
    "subscriptionId" = data.azurerm_client_config.current.subscription_id
    "tenantId" = data.azurerm_client_config.current.tenant_id
  })
}