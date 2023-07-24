source ./myEnvironment.sh

WEBAPP_PE_NAME='wa-pe-1'
WEBAPP_GROUP_ID='sites'
WEBAPP_RES_TAG='azurewebsites'

OPENAI_PE_NAME='oa-pe-1'
# see: https://learn.microsoft.com/en-gb/azure/private-link/private-endpoint-overview
OPENAI_GROUP_ID='account'
# https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration
OPENAI_RES_TAG='openai'

# this is the unwind of create..

RES_TAG=$OPENAI_RES_TAG

az network private-dns link vnet delete \
    --resource-group $RG \
    --zone-name "privatelink.${RES_TAG}.azure.com" \
    --name "dns-link-${RES_TAG}" \
    --yes

id=$(az cognitiveservices account list \
    --resource-group $RG \
    --query '[].[id]' \
    --output tsv)

subnetid=$(az network vnet subnet show \
-g $RG -n $SUBNET_VNI --vnet-name $VNET \
--query id --output tsv)

for i in $id
do
    COG_SVC=$(basename $i)

    # Delete a network rule for App Service VNet Integration
    # https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?tabs=azure-cli#grant-access-from-a-virtual-network
    az cognitiveservices account network-rule remove \
        -g $RG -n $COG_SVC \
        --subnet $subnetid

    az network private-endpoint delete \
        --name ${COG_SVC}-pe \
        --resource-group $RG

    az network private-endpoint dns-zone-group delete \
        --resource-group $RG \
        --endpoint-name ${COG_SVC}-pe \
        --name "zone-group-${RES_TAG}" 

    az resource update \
        --ids $i \
        --set properties.networkAcls="{'defaultAction':'Allow'}"

done

az network private-dns zone delete \
    --resource-group $RG \
    --name "privatelink.${RES_TAG}.azure.com" \
    --yes

# Web App

id=$(az webapp list \
    --resource-group $RG \
    --query '[].[id]' \
    --output tsv)

WEBAPP_NAME=$(basename $id)

RES_TAG=$WEBAPP_RES_TAG

az resource update --resource-group $RG \
    --name $WEBAPP_NAME \
    --resource-type "Microsoft.Web/sites" \
    --remove properties.vnetRouteAllEnabled

az webapp vnet-integration remove \
    --resource-group $RG \
    --name $WEBAPP_NAME

az network private-endpoint dns-zone-group delete \
    --resource-group $RG \
    --endpoint-name $WEBAPP_PE_NAME \
    --name "zone-group-${RES_TAG}" 

az network private-dns link vnet delete \
    --resource-group $RG \
    --zone-name "privatelink.${RES_TAG}.net" \
    --name "dns-link-${RES_TAG}" \
    --yes

az network private-dns zone delete \
    --resource-group $RG \
    --name "privatelink.${RES_TAG}.net" \
    --yes

az network private-endpoint delete \
    --name $WEBAPP_PE_NAME \
    --resource-group $RG 

