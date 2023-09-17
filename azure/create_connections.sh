#!/bin/bash

# Define the resource group, location, and name prefix for the local network gateways and VNET
RESOURCE_GROUP="aws-azure-vpn"
LOCATION="West Europe"
NAME_PREFIX=$RESOURCE_GROUP

# Define the internal VPC cidr block for AWS
AWS_VPC_CIDR="10.190.0.0/16"

# Define the shared keys for the VPN connections
SHARED_KEYS=(
  "UzmrtUXzSYF.aYoWvriqig6QMsz35XkB",
  "yEp7XI.ilT99sWCZ0SeLRUpXWNirg.M5"
)

# Define the list of AWS VPN IPs
AWS_VPN_IPS=(
  "3.126.105.29"
  "18.198.71.29"
)

# Create a local network gateway and VPN connection for each AWS VPN IP if they do not already exist
for ((i=0; i<${#AWS_VPN_IPS[@]}; ++i)); do
    # Check if the local network gateway already exists
    GATEWAY_NAME="$NAME_PREFIX-$i"
    GATEWAY_EXISTS=$(az network local-gateway show --name "$GATEWAY_NAME" --resource-group "$RESOURCE_GROUP" --query "name" -o tsv 2>/dev/null)

    if [ -n "$GATEWAY_EXISTS" ]; then
        echo "Local network gateway $GATEWAY_NAME already exists"
    else
        # Create the local network gateway
        echo "Creating local network gateway $GATEWAY_NAME"
        az network local-gateway create \
            --name "$GATEWAY_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --gateway-ip-address "${AWS_VPN_IPS[$i]}" \
            --local-address-prefixes $AWS_VPC_CIDR \
            --location "$LOCATION"

        if [ $? -ne 0 ]; then
            echo "Error creating local network gateway $GATEWAY_NAME"
            exit 1
        fi

        echo "Successfully created local network gateway $GATEWAY_NAME"
    fi

    # Check if the VPN connection already exists
    VPN_CONNECTION_EXISTS=$(az network vpn-connection show --name "$GATEWAY_NAME-connection" --resource-group "$RESOURCE_GROUP" --query "name" -o tsv 2>/dev/null)

    if [ -n "$VPN_CONNECTION_EXISTS" ]; then
        echo "VPN connection for local network gateway $GATEWAY_NAME already exists"
    else
        # Create the VPN connection
        echo "Creating VPN connection for local network gateway $GATEWAY_NAME"
        az network vpn-connection create \
            --name "$GATEWAY_NAME-connection" \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-gateway1 "$NAME_PREFIX-gateway" \
            --local-gateway2 "$GATEWAY_NAME" \
            --shared-key "${SHARED_KEYS[$i]}" \
            --location "$LOCATION"

        if [ $? -ne 0 ]; then
            echo "Error creating VPN connection for local network gateway $GATEWAY_NAME"
            exit 1
        fi

        echo "Successfully created VPN connection for local network gateway $GATEWAY_NAME"
    fi
done
