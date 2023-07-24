# assumes az login already run and subscription set
RG='<enter-name-of-your-resource-group>'
VNET='<enter-name-of-your-vnet>'
SUBNET_PE='<enter-name-of-your-subnet-for-private-endpoints>'
SUBNET_VNI='<enter-name-of-your-subnet-for-vnet-integration>'
# Creating a Jumpbox for a Jumpbox VM, details of creating the VM not included - or use Bastion 
SUBNET_JUMPBOX='<enter-name-of-your-subnet-for-jumpbox>'

## Example
#VNET_ADDR='10.0.0.0/16'
#SUBNET_PE_ADDR='10.0.0.0/24'
#SUBNET_JMP_ADDR='10.0.1.0/24'
#SUBNET_VNI_ADDR='10.0.2.0/24'
VNET_ADDR='<enter-cidr-range-for-vnet>'
SUBNET_PE_ADDR='<enter-cidr-range-for-private-endpoint-subnet>'
SUBNET_JMP_ADDR='<enter-cidr-range-for-jumpbox-subnet>'
SUBNET_VNI_ADDR='<enter-cidr-range-for-vnet-integration-subnet>'

