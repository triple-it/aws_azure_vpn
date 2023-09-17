#!/bin/bash

# Define the resource group, location, and name prefix for the local network gateways and VNET
RESOURCE_GROUP="aws-azure-vpn"
LOCATION="westeurope"
NAME_PREFIX=$RESOURCE_GROUP
VNET_NAME=$NAME_PREFIX-vnet

# Define the internal VPC cidr block for AWS
AWS_VPC_CIDR="10.190.0.0/16"

#Define the VNET cidr block for Azure
VNET_ADDRESS_PREFIX="10.191.0.0/16"
GATEWAY_ADDRESS_PREFIX="10.191.1.0/24"

# Check if resource group already exists
if az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "Resource group $RESOURCE_GROUP already exists."
else
    # Create the resource group
    echo "Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION || exit 1
fi

# Check if VNET already exists
if az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "VNET $VNET_NAME already exists."
else
    # Create the VNET and subnet
    echo "Creating VNET $VNET_NAME with subnet Subnet1"
    az network vnet create \
        --name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --address-prefixes "$VNET_ADDRESS_PREFIX" \
        --subnet-name "GatewaySubnet" \
        --subnet-prefix "$GATEWAY_ADDRESS_PREFIX" \
        --location "$LOCATION" || exit 1
fi

# Check if public IP address already exists
PUBLIC_IP_NAME=$NAME_PREFIX-pip
if az network public-ip show --name $PUBLIC_IP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "Public IP address $PUBLIC_IP_NAME already exists."
else
    # Create the public IP address
    echo "Creating public IP address $PUBLIC_IP_NAME"
    az network public-ip create \
        --name $PUBLIC_IP_NAME \
        --resource-group $RESOURCE_GROUP \
        --allocation-method Dynamic \
        --location $LOCATION || exit 1
fi

# Check if virtual network gateway already exists
GATEWAY_NAME="$NAME_PREFIX-gateway"
if az network vnet-gateway show --name $GATEWAY_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "Virtual network gateway $GATEWAY_NAME already exists."
else
    # Create the virtual network gateway
    az network vnet-gateway create \
        --name "$GATEWAY_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-ip-address "$PUBLIC_IP_NAME" \
        --vnet "$VNET_NAME" \
        --gateway-type Vpn \
        --vpn-type RouteBased \
        --sku VpnGw1 \
        --no-wait \
        --location "$LOCATION" || exit 1
fi

GATEWAY_PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP --name $PUBLIC_IP_NAME --query "ipAddress" -o tsv)

if [ $? -ne 0 ]; then
    echo "Error getting public IP address for virtual network gateway $NAME_PREFIX"
    exit 1
fi

echo "Successfully created virtual network gateway $NAME_PREFIX with public IP address $GATEWAY_PUBLIC_IP"
echo "Use Azure Public IP to create AWS infrastructure."
