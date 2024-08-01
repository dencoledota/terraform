provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "inchcapers" {
  name     = "inchcapers"
  location = "Southeast Asia"
}

resource "azurerm_app_service_plan" "inchcapers-appservice-plan" {
  name                = "app-service-plan-inchcapers"
  location            = azurerm_resource_group.inchcapers.location
  resource_group_name = azurerm_resource_group.inchcapers.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "inchcapers-appservice" {
  name                = "inchcapers-appservice"
  location            = azurerm_resource_group.inchcapers.location
  resource_group_name = azurerm_resource_group.inchcapers.name
  app_service_plan_id = azurerm_app_service_plan.inchcapers-appservice-plan.id

  site_config {
    python_version = "3.4"
    linux_fx_version = "DOCKER|${azurerm_container_registry.inchapers_acr.login_server}/inchcape-app:latest"
  }
  
  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITE_RUN_FROM_PACKAGE            = "1"
    ENABLE_ORYX_BUILD                   = "0"
    SCM_DO_BUILD_DURING_DEPLOYMENT      = "1"
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.inchapers_acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.inchapers_acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.inchapers_acr.admin_password
    "WEBSITES_PORT"                   = "5000"
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITES_ENABLE_APP_SERVICE_STORAGE"]
    ]
  }
}

resource "azurerm_app_service_source_control" "inchcapers-appservice-sourcecontrol" {
  app_id     = azurerm_app_service.inchcapers-appservice.id
  branch     = "main"
  repo_url   = "https://github.com/dencoledota/inchcapeapp.git"
}

resource "azurerm_container_registry" "inchapers_acr" {
  name                = "inchcapersacr${random_id.acr_id.hex}"
  resource_group_name = azurerm_resource_group.inchcapers.name
  location            = azurerm_resource_group.inchcapers.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = "testing"
  }
}

# Generate a unique suffix for the ACR name
resource "random_id" "acr_id" {
  byte_length = 4
}
