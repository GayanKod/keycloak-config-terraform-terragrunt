terraform {
  source = "/home/gayan/Documents/T/keycloak-terraform/vars.tf"
}

inputs = {
  server_url = "http://localhost:8080/auth"
  username = "admin"
  password = "password"
}
