terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-mvp"
    storage_account_name = "stazuredataplatformmvp"
    container_name       = "tfstate"
    key                  = "mvp.terraform.tfstate"
  }
}