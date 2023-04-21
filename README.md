# aws_azure_vpn

## Introduction:
This repository contains scripts to build infrastructure in both AWS and Azure that enable a site-to-site VPN tunnel between the two environments. This setup allows for secure communication between resources in both clouds as if they were on the same local network.
![architecture.png](images%2Farchitecture.png)

### Run ./azure/create_azure.sh to create the necessary resources in Azure
This script creates the necessary resources in Azure to establish a VPN gateway for a site-to-site VPN connection between Azure and AWS. Here is a list of each resource being created:
* **Resource group:** A resource group is created with the name specified in the RESOURCE_GROUP variable if it doesn't already exist. This will be used to contain all the resources created for this setup.
* **Virtual network (VNET):** A VNET is created with the name specified in the VNET_NAME variable if it doesn't already exist. The address prefix for the VNET is set to the value specified in the VNET_ADDRESS_PREFIX variable.
* **Subnet:** A subnet is created within the VNET with the name "GatewaySubnet" and the address prefix specified in the GATEWAY_ADDRESS_PREFIX variable.
* **Public IP address:** A public IP address is created with the name specified in the PUBLIC_IP_NAME variable if it doesn't already exist.
* **Virtual network gateway:** A virtual network gateway is created with the name specified in the GATEWAY_NAME variable if it doesn't already exist. This gateway is associated with the VNET and the public IP address created earlier, and is configured as a VPN gateway using the --gateway-type Vpn and --vpn-type RouteBased options. The SKU for the gateway is set to VpnGw1.
Once the script has finished executing, it outputs the public IP address of the virtual network gateway, which is needed to create the AWS infrastructure for the VPN connection.

### Update the Terraform declaration
In ./terraform/main.tf, specify the public IP address of the VPN gateway that was created in step 1.

### Apply Terraform to build the AWS infrastructure.
```
terraform init
terraform plan -out=plan.out
terraform apply
```

### Download the VPN configuration file from AWS.
![vpn_configuration.png](images%2Fvpn_configuration.png)

### Update the variables in ./azure/create_connections.sh to include the correct IP addresses and shared secret for the VPN connection.


### Run the shell script ./azure/create_connections.sh to create the VPN connection between Azure and AWS.
This script creates a local network gateway and VPN connection for each AWS VPN IP address provided in the AWS_VPN_IPS array. Here is a list of each resource being created:
* **Local network gateway:** A local network gateway is created with a name consisting of the name prefix ($NAME_PREFIX) and an index number based on the position of the AWS VPN IP address in the AWS_VPN_IPS array (e.g. $NAME_PREFIX-0 for the first IP address). The gateway IP address is set to the value of the current AWS VPN IP address. The local address prefixes are set to the internal VPC CIDR block specified in the $AWS_VPC_CIDR variable.
* **VPN connection:** A VPN connection is created with a name consisting of the local network gateway name ($GATEWAY_NAME) followed by -connection (e.g. $NAME_PREFIX-0-connection for the first local network gateway). The connection is established between the virtual network gateway created in Azure and the local network gateway created in the previous step. The shared key for the connection is set to the value of the corresponding element in the SHARED_KEYS array based on the index number of the current AWS VPN IP address.
Once the script has finished executing, there should be a local network gateway and VPN connection for each AWS VPN IP address specified, allowing for a site-to-site VPN connection between Azure and AWS.

### Confirm that the VPN tunnels are up and running by checking the Azure and AWS dashboards.
![vpn_status.png](images%2Fvpn_status.png)

### Run ./azure/create_vm.sh to create a virtual machine in Azure to test connectivity.
This script creates an Ubuntu virtual machine in Azure with a public IP address and a network security group (NSG) attached. The NSG allows inbound traffic from the AWS VPC CIDR range specified in the $AWS_VPC_CIDR variable and allows all outbound traffic to any destination. Here is a list of each resource being created:
* Network Security Group: A new NSG is created with a name consisting of the name prefix ($NAME_PREFIX) followed by -nsg (e.g. $NAME_PREFIX-nsg). Two rules are added to the NSG: one to allow all inbound traffic from the AWS CIDR range and another to allow all outbound traffic.
* Subnet: The script checks if a subnet named Subnet1 already exists in the VNET named $VNET_NAME in the resource group named $RESOURCE_GROUP. If the subnet does not exist, it is created with an address prefix of $SUBNET1_ADDRESS_PREFIX. If the subnet does exist, the script checks if the NSG is attached to the subnet. If it is not, the script updates the subnet to attach the NSG.
* Public IP address: The script checks if a public IP address with the name $PUBLIC_IP_NAME already exists in the resource group named $RESOURCE_GROUP. If it does not, a new public IP address is created with a dynamic allocation method.
* Virtual machine: The script checks if a virtual machine named $VM_NAME already exists in the resource group named $RESOURCE_GROUP. If it does not, a new Ubuntu virtual machine is created with the following properties:
  * Image: Canonical:UbuntuServer:18.04-LTS:latest
  * Size: Standard_B1s
  * Admin username: adminuser
  * Admin password: AdminPassw0rd123!
  * NSG: $NSG_NAME
  * VNET name: $VNET_NAME
  * Subnet: Subnet1
  * Public IP address: $PUBLIC_IP_NAME

Once the script has finished executing, there should be an Ubuntu virtual machine running in Azure with a public IP address and an NSG allowing inbound traffic from the AWS VPC CIDR range.

### Test the VPN connection by pinging resources in AWS from the virtual machine in Azure.
![ping.png](images%2Fping.png)

## Summary
That's it! With these steps, you should have a fully functioning site-to-site VPN tunnel between AWS and Azure, allowing for secure communication between resources in both clouds.