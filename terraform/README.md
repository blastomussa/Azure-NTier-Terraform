## Requires the following variables definitions to be saved in a terraform.tfvars file

subscription_id = Azure subscription ID
Github_pat = GitHub Personal Access token scoped for public pull access and status
	access to GitHub repository
appID = application ID for service principle in Azure AD
password = password associated with service principle

```
subscription_id = "***********************************"
github_pat      = "***********************************"
appId           = "***********************************"
password        = "***********************************"
```
![Azure Architecture](https://github.com/blastomussa/Azure-NTier-Terraform/blob/master/diagram/azure-architecture.png)
