# Terraform with Azure by setting up a development environment
# Author Achraf BEN CHEIKH LADHARI
## Step 1: Install Azure CLI
```
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
```
## Step 2: Connect to Azure

``This command will open new tab in your browser and ask you to login with your Azure account then will connect automatically``

```
az login
```
## Step 3: Generate SSH Key 
### Save the key in the current dir and name it "devopsazurekey" or change the code and provide your path and the name in the line 107 and 125 in main.tf
```
ssh-keygen -t rsa
```

## Step 4: Run the following commands
```
terraform init
terraform plan
terraform apply -auto-approve
```

## Step 5: Connect to the VM
---
### Ubuntu VM SSH:
```
ssh -i "azurekeygenerated" azureuser@public_ip_address
```
