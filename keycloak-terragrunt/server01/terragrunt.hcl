terraform {
  source = "/home/gayan/Documents/keycloak-config-with-terragrunt/keycloak-terraform"
}

inputs = {
  server_url = "http://localhost:8080/auth"
  username = "admin"
  password = "password"
}
