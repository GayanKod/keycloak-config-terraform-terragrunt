terraform {
  source = "/home/gayan/Documents/T/keycloak-terraform/main.tf"
}

inputs = {
  server_url = "http://localhost:8080/auth"
  username = "admin"
  password = "password"
}
