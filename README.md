# Azure Project
## UML - MSIT 5650: Cloud Computing F22

Project repository for Azure term project. N-tier application consisting of an AKS
backend, a Flask frontend container instance, an application gateway, a CosmosDB
MongoDB database and a Azure Container registry.

Container images are built automatically on deployment with an ACR task, which is
also triggered after every commit to this repository's master branch.

The goal of this project is to deploy as many resources as possible with terraform.


![Azure Architecture](https://github.com/blastomussa/Azure-NTier-Terraform/blob/master/diagram/azure-architecture.png)
