module "ecr" {
  source = "git::https://github.com/vaheedgit26/Infra-1.0.git//modules/ecr"

  project = var.project   # "roboshop"
  env     = var.env       # "dev"
  
  repositories = [
    "roboshop-dev/frontend",
    "roboshop-dev/catalogue",
    "roboshop-dev/cart",
    "roboshop-dev/user",
    "roboshop-dev/shipping",
    "roboshop-dev/payment"
  ]
  
}
