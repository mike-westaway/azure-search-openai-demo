# Azure Search OpenAI Demo Helpers

This repo adds helpers to the Azure Search Open AI Demo to configure it for 
- Private Endpoints

First setup the Azure Search Open AI Demo as described here
https://github.com/Azure-Samples/azure-search-openai-demo

There are multiple ways to configure the Demo
I'm going to use the simplest, azd, approach

Notes: 
- requires PowerShell 7
- defaults will create a Resource Group: rg-azure-search-openai-demo-dev
- azd auth login -tenant-id <tenant id>
- azd init -t 
- azd up

# Create Private Endpoints
./runCreatePrivateEndpoints.sh

# Test
To test, create a Bastion host or Jumpbox VM and navigate to the Webapp endpoint

# Delete Private Endpoints
To reset to default pubic access
./runDeletePrivateEndpoints.sh

# Roadmap
- Add Monitoring helpers
- Add Authentication helpers
  
# Background

VNet
https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-cli#create-a-virtual-network-and-subnet

Web App Private Endpoint
https://learn.microsoft.com/en-us/azure/private-link/create-private-endpoint-cli?tabs=dynamic-ip

Private Endpoints
https://learn.microsoft.com/en-gb/azure/private-link/private-endpoint-overview

DNS for Private Endpoints
https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration

Cognitive Services
https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?tabs=azure-cli#grant-access-from-a-virtual-network
