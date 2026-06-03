terraform {
  backend "azurerm" {
    resource_group_name  = "rg-azure-dataplatform-mvp"
    storage_account_name = "stazuredataplatfrommvp"
    container_name       = "tfstate"
    key                  = "mvp.terraform.tfstate"
  }
}
