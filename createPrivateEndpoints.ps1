# Check if ./myEnvironment.sh exists
if (-not (Test-Path ./myEnvironment.ps1)) {
    # Check if ./myEnvironment-local.sh exists
    if (Test-Path ./myEnvironment-local.ps1) {
        # Copy ./myEnvironment-local.sh to ./myEnvironment.sh
        Write-Host "Environment not setup, local environment defined, copying to myEnvironment.sh"
        Copy-Item ./myEnvironment-local.ps1 ./myEnvironment.ps1
    }
    else {
        # Exit with a message
        Write-Host "Environment not setup, local environment not defined, copy ./myEnvironment-template.ps1 to ./myEnvironment-local.ps1 and edit values. Then re-run this script"co
        exit
    }
}

. ./myEnvironment.ps1

$WEBAPP_PE_NAME='wa-pe-1'
$WEBAPP_GROUP_ID='sites'
$WEBAPP_RES_TAG='azurewebsites'

$OPENAI_PE_NAME='oa-pe-1'
# see: https://learn.microsoft.com/en-gb/azure/private-link/private-endpoint-overview
$OPENAI_GROUP_ID='account'
#https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration
$OPENAI_RES_TAG='openai'

# Get the number of vnets with the given name in the resource group
$vnetCount = (az network vnet list -g $RG --query "[?name == '$VNET'] | length(@)" | ConvertFrom-Json)

# If the vnet does not exist, create it and its subnets
if ($vnetCount -eq 0) {
    # Create the vnet with the private endpoint subnet
    az network vnet create `
        --name $VNET `
        --resource-group $RG `
        --address-prefix $VNET_ADDR `
        --subnet-name $SUBNET_PE `
        --subnet-prefixes $SUBNET_PE_ADDR

    # Create the virtual network integration subnet
    az network vnet subnet create `
        --vnet-name $VNET `
        --resource-group $RG `
        --address-prefix $VNET_ADDR `
        --name $SUBNET_VNI `
        --address-prefixes $SUBNET_VNI_ADDR

    # Create the jumpbox subnet
    az network vnet subnet create `
        --vnet-name $VNET `
        --resource-group $RG `
        --address-prefix $VNET_ADDR `
        --name $SUBNET_JUMPBOX `
        --address-prefixes $SUBNET_JMP_ADDR
}

# Web App
$id = az webapp list `
    --resource-group $RG `
    --query '[].[id]' `
    --output tsv

$WEBAPP_NAME = Split-Path -Leaf $id
$RES_TAG = $WEBAPP_RES_TAG

az network private-endpoint create `
    --connection-name $WEBAPP_PE_NAME `
    --name $WEBAPP_PE_NAME `
    --private-connection-resource-id $id `
    --resource-group $RG `
    --subnet $SUBNET_PE `
    --group-id $WEBAPP_GROUP_ID `
    --vnet-name $VNET

az network private-dns zone create `
    --resource-group $RG `
    --name "privatelink.${RES_TAG}.net"

az network private-endpoint dns-zone-group create `
    --resource-group $RG `
    --endpoint-name $WEBAPP_PE_NAME `
    --name "zone-group-${RES_TAG}" `
    --private-dns-zone "privatelink.${RES_TAG}.net" `
    --zone-name $RES_TAG

az network private-dns link vnet create `
    --resource-group $RG `
    --zone-name "privatelink.${RES_TAG}.net" `
    --name "dns-link-${RES_TAG}" `
    --virtual-network $VNET `
    --registration-enabled false

az webapp vnet-integration add `
    --resource-group $RG `
    --name $WEBAPP_NAME `
    --vnet $VNET `
    --subnet $SUBNET_VNI

az resource update --resource-group $RG `
    --name $WEBAPP_NAME `
    --resource-type "Microsoft.Web/sites" `
    --set properties.vnetRouteAllEnabled=true

# Open AI - 2 Cog Services: OpenAI and Form Recognizer
$RES_TAG = $OPENAI_RES_TAG
# very important - DNS Zone must be called privatelink.openai.azure.com
# this is called out indirectly on the DNS Configuration page for the Private Endpoint
# to test it is working correctly, nslookup the Public DNS from a VM on the VNet, you should get the private IP
az network private-dns zone create `
    --resource-group $RG `
    --name "privatelink.${RES_TAG}.azure.com"

az network private-dns link vnet create `
    --resource-group $RG `
    --zone-name "privatelink.${RES_TAG}.azure.com" `
    --name "dns-link-${RES_TAG}" `
    --virtual-network $VNET `
    --registration-enabled false

$id = (az cognitiveservices account list `
    --resource-group $RG `
    --query '[].[id]' `
    --output tsv)

# Loop through each id
foreach ($i in $id) {
    # Get the base name of the id
    $COG_SVC = Split-Path -Leaf $i

    # Create a private endpoint for the id
    az network private-endpoint create `
        --connection-name "${COG_SVC}-co" `
        --name "${COG_SVC}-pe" `
        --private-connection-resource-id $i `
        --resource-group $RG `
        --subnet $SUBNET_PE `
        --group-id $OPENAI_GROUP_ID `
        --vnet-name $VNET

    # Create a dns zone group for the private endpoint
    az network private-endpoint dns-zone-group create `
        --resource-group $RG `
        --endpoint-name "${COG_SVC}-pe" `
        --name "zone-group-${RES_TAG}" `
        --private-dns-zone "privatelink.${RES_TAG}.azure.com" `
        --zone-name $RES_TAG

    # Deny access from any network
    # https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?tabs=azure-cli#grant-access-from-a-virtual-network
    az resource update `
        --ids $i `
        --set properties.networkAcls="{'defaultAction':'Deny'}"

    # Add a network rule for App Service VNet Integration
    # https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?tabs=azure-cli#grant-access-from-a-virtual-network
    # Get the subnet id
    $subnetid = az network vnet subnet show `
        -g $RG -n $SUBNET_VNI --vnet-name $VNET `
        --query id --output tsv

    # Add the network rule
    az cognitiveservices account network-rule add `
        -g $RG -n $COG_SVC `
        --subnet $subnetid
}
