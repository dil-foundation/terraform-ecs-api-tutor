# denzi-tenant

Module to orchestrate various modules to build a single tenant. A separate folder should be created per tenant similar to this one to maintain the state of it. 

Provide values for below local variables to spin up the new infrastructure for DEV environment
Below values are for reference only.

  tenant_name             = "tenant5"
  environment             = "dev"
  cidr_block              = "18.255.0.0/16"
  db_username             = "tenant5"
  db_password             = "tenant123$"
  db_identifier           = "tenant5-db-instance"
  db_instance             = "mysql-tenant5-instance"
  tf_remote_state_bucket  = "tenant5-terraform-remote-state"

  Also update the new tf bucket name at the bottom of the script with value of "tf_remote_state_bucket"
  terraform {
  backend "s3" {
    bucket = "tenant5-terraform-remote-state"
