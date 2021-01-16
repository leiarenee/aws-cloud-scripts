# AWS Client VPN Management Tool

This script activates or terminates VPN Subnet associations on demand to reduce VPN costs. 


### Version

Version 1.0.0

### Usage

./vpn.sh [CMD] [Arguments]

### Required Arguments List

* CMD [enable|disable]                                     Command to run. One of (enable/disable)

### Optional Arguments List

* -p | --profile                                           AWS Profile name
* -c | --vpc-id [vpc-3fc...12]                             VPC Id
* -n | --vpn-endpoint-id [cvpn-endpoint-12f61....78]       Client Vpn Endpoint Id
* -a | --availability-zone [eu-central-1]                  Availability zone to associate
* -l | --licence                                           Show licence
* -h | --help                                              Show help

### Examples

```sh
./vpn.sh enable 
./vpn.sh disable 
./vpn.sh enable --vpn-endpoint-id cvpn-endpoint-92e611a9dg7b858dx --subnet-id subnet-603va91c 
./vpn.sh enable -p testAccount
```

### Links

* [AWS Client VPN Documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html)
* [AWS Client VPN Pricing](https://aws.amazon.com/vpn/pricing/)

<img src="../images/aws_cvpn.png" width="100">

In AWS Client VPN you are charged for the number of active client connections per hour and the number of subnets that are associated to Client VPN per hour. Billing starts once the subnet association is made and each partial hour consumed is pro-rated for the hour. As users are connected it is charged a second fee based on the number of active clients that are connected to the Client VPC endpoint, per hour.

* AWS Client VPN endpoint association - $0.10 per hour per subnet
* AWS Client VPN connection - $0.05 per hour

### Outputs

_Command:_

```sh
./vpn.sh status
```

_Output:_

```sh
Running Command : status
- Fetching default Vpc Id...
  VPC ID : vpc-7fc47215
- Fetching VPN End Points...
  VPN Endpoint ID : cvpn-endpoint-02f611a9df7b878db
- Fetching availability zones...
  Awailable zones are : eu-central-1a   eu-central-1b   eu-central-1c
  Choosing eu-central-1a
- Fetching Subnet ids...
  Subnet ID : subnet-7737a91d
- Fetching Vpn status...
  VPN Status : available

VPN is ACTIVE
```

### Environment file

If you create a file named as `.env` within the same folder, script will source variables from there.

Example `.env` file

```sh
profile=test
```

_Variables_

* action=[status|enable|disable]
* vpc_id
* vpn_endpoint_id
* availability_zone
* profile
* no_color