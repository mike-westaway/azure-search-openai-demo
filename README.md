# First setup the Azure Search Open AI Demo as described here
https://github.com/Azure-Samples/azure-search-openai-demo

# I'm going to use the azd approach
# requires PowerShell 7
# defaults will create a Resource Group: rg-azure-search-openai-demo-dev

azd auth login -tenant-id <tenant id>
azd init -t 

azd up

# inventory the Azure Resources and write a script to create Private endpoints for each

# run the new script

# inventory public access and write a script to disable

# Background

VNet
https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-cli#create-a-virtual-network-and-subnet

Web App Private Endpoint
https://learn.microsoft.com/en-us/azure/private-link/create-private-endpoint-cli?tabs=dynamic-ip

Private Endpoints
https://learn.microsoft.com/en-gb/azure/private-link/private-endpoint-overview

DNS for Private Endpoints
https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration

# Cognitive Services
https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?tabs=azure-cli#grant-access-from-a-virtual-network
