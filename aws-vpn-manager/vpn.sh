#!/bin/bash

function licence(){
  cat << LICENCE >&2
  MIT Licence - Copyright (c) 2020 Leia Renée
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
LICENCE
}

# colors
function define_colors(){
  if [[ ! $no_color == "true" ]]
  then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
  fi
}

function usage(){
  echo
  echo -e "${GREEN}------------------------- AWS Client VPN Management Script  ------------------------${NC} "
  echo
  cat << USAGE >&2
  Usage:
      $CMDNAME [CMD] [Arguments]

      Required Arguments List:
        CMD [enable|disable]                                     Command to run. One of (enable/disable)

      Optional Arguments List:
        -p | --profile                                           AWS Profile name
        -c | --vpc-id [vpc-3fc...12]                             VPC Id
        -n | --vpn-endpoint-id [cvpn-endpoint-12f61....78]       Client Vpn Endpoint Id
        -a | --availability-zone [eu-central-1]                  Availability zone to associate
        -r | --no-color                                          Disable colors and tables
        -l | --licence                                           Show licence
        -h | --help                                              Show help

  Examples:
      $CMDNAME enable 
      $CMDNAME disable 
      $CMDNAME status 
      $CMDNAME enable --vpn-endpoint-id cvpn-endpoint-92e611a9dg7b858dx --subnet-id subnet-603va91c 
      $CMDNAME enable -p testAccount
USAGE
}

# Version 
function version(){
  echo 
  echo -e "Version 1.0.0 ${BLUE}    https://github.com/leiarenee/scripts/blob/main/aws-client-vpn/vpn.sh${NC}"
  echo
}

# process arguments
function process_arguments(){
  if [[ $# -eq 0 ]]
  then
    echo "Command should be specified. Please run $CMDNAME --help for details."
    exit 1
  fi
  table_out="table"
  while [[ $# -gt 0 ]]
  do
      case "$1" in
          enable | disable | status)
          action=$1
          shift 1
          echo "Running Command : $action"
          ;;
          -c | --vpc-id)
          vpc_id=$2
          shift 2
          ;;
          -n | --vpn-endpoint-id)
          vpn_endpoint_id=$2
          shift 2
          ;;
          -a | --availability-zone)
          availability_zone=$2
          shift 2
          ;;
          -p | --profile)
          profile=$2
          shift 2
          ;;
          -r | --no-color)
          no_color=true
          table_out="text"
          shift 1
          ;;
          -l | --licence)
          licence
          exit 1
          ;;
          -h | --help)
          usage
          version
          exit 1
          ;;
          *)
          echo
          echo -e "${RED}Unknown argument: $1${NC}"
          usage
          exit 1
          ;;
      esac
  done
}

# Prepare AWS argument list and calculate automatic values
function prepare_aws_arguments(){
  # AWS Profile
  if [[ -z $profile ]]
  then
    profile_argument=""
  else
    profile_argument="--profile $profile"
  fi
  get_caller_identity

  # Vpc Id
  if [[ -z $vpc_id ]]
  then
    find_vpc
  fi

  # Client Vpn End Point Id 
  if [[ -z $vpn_endpoint_id ]]
  then
    find_vpn_endpoint_id
  else
    echo -e "  Specified VPN Endpoint ID : ${GREEN}$vpn_endpoint_id${NC}"
  fi

}

# Check AWS Cli Version
function check_aws_cli_version(){
  accepted_version=2
  accepted_pattern="aws-cli/$accepted_version"
  aws_version=$(aws --version)
  echo
  echo "aws cli version is : $aws_version"
  set +e
  check_version=$(echo $aws_version | grep -o "$accepted_pattern")
  set -e
  if [ -z $check_version ]
  then
    echo
    echo -e "${RED}Error: Aws client version mismatch. Version >= $accepted_version.0 Required"
    echo
    exit 1
  fi
}

# Get AWS Caller Identity
function get_caller_identity(){
  echo - Fetching AWS Caller Identity...
  aws $profile_argument sts get-caller-identity --output $table_out
}

# Find Default VPC Id
function find_vpc(){
  echo - Fetching default Vpc Id...
  vpc_id=$(aws ec2 $profile_argument describe-vpcs --query "Vpcs[*].[VpcId,IsDefault]" --output text | grep True | awk '{print $1}')    
  echo -e "  VPC ID : ${GREEN}$vpc_id${NC}"
}

# Function: Find VPN End Point Id
function find_vpn_endpoint_id(){
  echo - Fetching VPN End Points...
  vpn_endpoint_id_list=$(aws $profile_argument ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[?VpcId==\`$vpc_id\`].ClientVpnEndpointId" --output=text)
  if [ -z $vpn_endpoint_id_list ]
  then
    echo
    echo -e "${RED}There is no VPN endpoint detected in $vpc_id${NC}"
    echo
    exit 1
  else
    vpn_endpoint_id=($vpn_endpoint_id_list) # make it array and return first element 
    if [[ $vpn_endpoint_id_list != $vpn_endpoint_id ]]
    then
      echo
      echo -e "${RED}Error: Multiple VPN Endpoints found! ${NC}"
      echo "$vpn_endpoint_id_list"
      echo "Please specify with [-n | --vpn-endpoint-id] argument."
      echo
      exit 1
    fi 
  fi
  echo -e "  VPN Endpoint ID : ${GREEN}$vpn_endpoint_id${NC}"
}

# get Availability Zones
function find_availability_zone(){
  echo - Fetching availability zones...
  echo "  Awailable zones are :" 
  aws $profile_argument ec2 describe-availability-zones --query "AvailabilityZones[][ZoneName,State]" --output $table_out

  # Fetch healty Zones
  availability_zone_list=$(aws $profile_argument ec2 describe-availability-zones --query "AvailabilityZones[?State==\`available\`].ZoneName" --output text)
  if [[ "$availability_zone" == "" ]]
  then
    availability_zone=($availability_zone_list)
    echo -e "  Choosing ${GREEN}$availability_zone${NC}"
  else
    if echo "$availability_zone_list" | grep -w "$availability_zone"
    then
      echo -e "${GREEN}  Availability zone $availability_zone is available${NC}"
    else
      echo
      echo -e "${RED}Error: Availability zone $availability_zone is not available or does not exist${NC}"
      exit 1
    fi
  fi

  
}

# find subnet
function find_subnet_id(){
  echo - Fetching Subnet ids...
  subnet_id=$(aws $profile_argument ec2 describe-subnets --query "Subnets[?VpcId==\`$vpc_id\`] | [?AvailabilityZone==\`$availability_zone\`].SubnetId" --output text)
  echo -e "  Subnet ID : ${GREEN}$subnet_id${NC}"
}

# Fetch Status
function fetch_vpn_status(){
  vpn_status=$(aws $profile_argument ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids $vpn_endpoint_id --query "ClientVpnEndpoints[0].Status.Code" --output text)
}

# Get Status
function get_vpn_status(){
  echo - Fetching Vpn status...
  fetch_vpn_status
  if [[ "$vpn_status" == "available" ]]
  then
    echo -e "  VPN Status : ${GREEN}$vpn_status${NC}"
  else
    echo -e "  VPN Status : ${RED}$vpn_status${NC}"
  fi
}

# Show Stat Command
function show_stat(){
  echo
  if [[ "$vpn_status" == "available" ]]
  then
    echo -e "${GREEN}VPN is ACTIVE${NC}"
  else
    echo -e "${RED}VPN is OFFLINE ${NC}"
  fi
  echo
}

# Function: Enable VPN Command
function enable_vpn(){
  SECONDS=0
  if [[ "$vpn_status" == "available" ]]
  then
    echo
    echo -e "${GREEN}VPN is Already ACTIVE.${NC}"
  else
    aws $profile_argument ec2 associate-client-vpn-target-network \
                  --subnet-id $subnet_id \
                  --client-vpn-endpoint-id $vpn_endpoint_id
                  

    while [[ "$vpn_status" != "available" ]] 
    do
    fetch_vpn_status
    route_stats=$(aws $profile_argument ec2 describe-client-vpn-routes --client-vpn-endpoint-id $vpn_endpoint_id --query "Routes[][TargetSubnet,Status.Code]" --output text | xargs)
    echo "[$SECONDS Seconds Elapsed] VPN Status: $vpn_status     Route Stats: $route_stats"
    sleep 10
    done
    echo
    echo -e "${GREEN}VPN ACTIVATED in $SECONDS seconds.${NC}"
    echo
  fi
}

# Function: Disable VPN Command
function disable_vpn(){
  connections=$(aws $profile_argument ec2 describe-client-vpn-connections --client-vpn-endpoint-id $vpn_endpoint_id --query "Connections[?Status.Code==\`active\`].ConnectionId" --output text)
  if [[ "$connections" != "" ]]
  then
    echo
    echo -e "Error: ${RED}There are active connections. ${NC}"
    echo "Active connection list : $connections"
    echo "If you are connected please disconnect first. If you are recently disconnected wait for 30 seconds and try again."
    exit 0
  fi

  fetch_vpn_status
  if [[ "$vpn_status" == "pending-associate" ]]
  then
    echo
    echo -e "${RED}VPN Already Deactivated.${NC}"
    echo
  else
    SECONDS=0
    association_ids=($(aws $profile_argument ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id $vpn_endpoint_id --query "ClientVpnTargetNetworks[].AssociationId" --output text))
    for association_id in "${association_ids[@]}"
    do
      aws $profile_argument ec2 disassociate-client-vpn-target-network \
                    --client-vpn-endpoint-id $vpn_endpoint_id \
                    --association-id $association_id
    done

    route_stats=" "
    echo
    # while [[ "$route_stats" != "" ]] 
    while [[ "$vpn_status" == "available" ]]
    do
      fetch_vpn_status
      route_stats=$(aws $profile_argument ec2 describe-client-vpn-routes --client-vpn-endpoint-id $vpn_endpoint_id --query "Routes[][TargetSubnet,Status.Code]" --output text | xargs)
      echo "[$SECONDS Seconds Elapsed] VPN Status: $vpn_status     Route Stats: $route_stats"
      sleep 10
    done

    echo
    echo -e "${RED}VPN DEACTIVATED in $SECONDS seconds.${NC}"
    echo

  fi
}


# --------- Main Routine --------------
set -e
CMDNAME=./${0##*/}
[ -f .env ] && source .env
process_arguments $@
define_colors
# check_aws_cli_version
prepare_aws_arguments
find_availability_zone
find_subnet_id
get_vpn_status


# Switch Action
case "$action" in
  enable)
  enable_vpn
  ;;
  disable)
  disable_vpn
  ;;
  status)
  show_stat
  ;;
esac
