#!/bin/bash

# Define the resource group, location, and name prefix for the local network gateways and VNET
RESOURCE_GROUP="aws-azure-vpn"
LOCATION="westeurope"
NAME_PREFIX=$RESOURCE_GROUP
VNET_NAME=$NAME_PREFIX-vnet

# Define the internal VPC cidr block for AWS
AWS_VPC_CIDR="10.190.0.0/16"

# Define the virtual machine name and image
VM_NAME="${NAME_PREFIX}-vm"
VM_IMAGE_URN="Canonical:UbuntuServer:18.04-LTS:latest"

# Define the address prefix for Subnet1
SUBNET1_ADDRESS_PREFIX="10.191.0.0/24"

# Create a new Network Security Group
NSG_NAME="${NAME_PREFIX}-nsg"
if az network nsg show --name $NSG_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "Network Security Group $NSG_NAME already exists."
else
    az network nsg create \
        --name "$NSG_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" || exit 1
fi

# Create a rule to allow all inbound traffic from the AWS CIDR range
if az network nsg rule show --name "allow-aws-inbound" --nsg-name "$NSG_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Network Security Group rule to allow inbound traffic from AWS CIDR range already exists."
else
    az network nsg rule create \
        --name "allow-aws-inbound" \
        --nsg-name "$NSG_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --priority 100 \
        --access Allow \
        --protocol '*' \
        --direction Inbound \
        --source-address-prefixes "$AWS_VPC_CIDR" \
        --destination-address-prefix '*' \
        --destination-port-range '*' \
        --description "Allow all inbound traffic from AWS VPC CIDR range" || exit 1
fi

# Create a rule to allow all outbound traffic to any destination
if az network nsg rule show --name "allow-all-outbound" --nsg-name "$NSG_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Network Security Group rule to allow all outbound traffic already exists."
else
    az network nsg rule create \
        --name "allow-all-outbound" \
        --nsg-name "$NSG_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --priority 200 \
        --access Allow \
        --protocol '*' \
        --direction Outbound \
        --source-address-prefix '*' \
        --destination-address-prefix '*' \
        --destination-port-range '*' \
        --description "Allow all outbound traffic to any destination" || exit 1
fi

# Check if Subnet1 already exists
if az network vnet subnet show --name "Subnet1" --vnet-name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Subnet1 already exists."
else
    az network vnet subnet create \
        --name "Subnet1" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --address-prefix "$SUBNET1_ADDRESS_PREFIX"
fi

# Check if NSG is already attached to Subnet1
if az network vnet subnet show --name "Subnet1" --vnet-name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" --query "networkSecurityGroup.id" -o tsv | grep -q $NSG_NAME; then
    echo "Network Security Group $NSG_NAME is already attached to Subnet1."
else
    az network vnet subnet update \
        --name "Subnet1" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --network-security-group "$NSG_NAME"
fi

# Check if public IP address already exists
PUBLIC_IP_NAME=$NAME_PREFIX-vm-pip
if az network public-ip show --name $PUBLIC_IP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "Public IP address $PUBLIC_IP_NAME already exists."
else
    # Create the public IP address
    echo "Creating public IP address $PUBLIC_IP_NAME"
    az network public-ip create \
        --name $PUBLIC_IP_NAME \
        --resource-group $RESOURCE_GROUP \
        --allocation-method static \
        --location $LOCATION || exit 1
fi

VM_PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP --name $PUBLIC_IP_NAME --query "ipAddress" -o tsv)

# Create a new Ubuntu VM with the NSG attached
if az vm show --name $VM_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "Virtual Machine $VM_NAME already exists."
else
    az vm create \
        --name "$VM_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --image $VM_IMAGE_URN \
        --size "Standard_B1s" \
        --admin-username "adminuser" \
        --admin-password "AdminPassw0rd123!" \
        --nsg "$NSG_NAME" \
        --vnet-name "$VNET_NAME" \
        --subnet "Subnet1" \
        --public-ip-address $VM_PUBLIC_IP || exit 1

    echo "Successfully created Ubuntu VM $VM_NAME with NSG $NSG_NAME."
fi
