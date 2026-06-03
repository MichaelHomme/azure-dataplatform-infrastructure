terraform {
  backend "azurerm" {
    resource_group_name  = "rg-auzre-dataplatform-mvp"
    storage_account_name = "stazuredataplatofrmmvp"
    container_name       = "tfstate"
    key                  = "mvp.terraform.tfstate"
  }
}
