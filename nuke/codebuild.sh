#!/bin/bash
set -e
# Bash script for cleaning accounts
# https://www.1strategy.com/blog/2019/07/16/automated-clean-up-with-aws-nuke-in-multiple-accounts/

# Remove current temporary directory if it already exits
rm -R -f temp

# Create a termporary directory
mkdir temp

# Download template file
aws s3api get-object --bucket master-config-files --key aws-nuke-config-template.yaml aws-nuke-config-template.yaml

# Download aws-nuke
wget --progress=dot:giga -O download.zip https://github.com/rebuy-de/aws-nuke/releases/download/v2.15.0/aws-nuke-v2.15.0-linux-amd64.tar.gz
unzip -q ./download.zip -d /bin
chmod +x /bin/aws-nuke

# Get account ids which belong the parent organizational unit and write the output to accounts.txt
aws organizations list-accounts-for-parent \
  --parent-id $NUKE_PARENT \
  | jq -r '.Accounts | map(.Id)' | jq -r '.[]' \
  > temp/accounts.txt

cat temp/accounts.txt

while read -r line 
do
  echo "Assuming Role for Account $line"

  # Assume Role and get credentials
  aws sts assume-role \
    --role-arn arn:aws:iam::$line:role/OrganizationAccountAccessRole \
    --role-session-name account-$line \
    --query "Credentials" \
    > temp/$line.json

  # cat temp/$line.json

  # Extract session credentials and write it to environment variables
  export AWS_ACCESS_KEY_ID=$(cat temp/$line.json | jq -r .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(cat temp/$line.json | jq -r .SecretAccessKey)
  export AWS_SESSION_TOKEN=$(cat temp/$line.json | jq -r .SessionToken)

  echo "ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
  echo "SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
  echo "SESSION_TOKEN: $AWS_SESSION_TOKEN"

  # Dublicate aws-nuke-config.yaml
  cp aws-nuke-config-template.yaml temp/$line.yaml

  # Replace account number
  sed -i -e "s/000000000000/$line/g" temp/$line.yaml

  echo "Configured aws-nuke-config.yaml"
  cat temp/$line.yaml

  # Run aws-nuke
  echo "Running aws-nuke on account $line"
  x=2 # Number of repeatition


  while [ $x -gt 0 ]
  do
    
    echo "---------------"
    echo "$x STEP LEFT"
    echo

    # Run aws-nuke
    ./aws-nuke -c temp/$line.yaml --force \
    --access-key-id $AWS_ACCESS_KEY_ID --secret-access-key $AWS_SECRET_ACCESS_KEY --session-token $AWS_SESSION_TOKEN \
    --no-dry-run \
    | tee -a temp/aws-nuke.log

    # Increase count 
    x=$(($x-1))

    # ---
    # Manually clean up RDS option groups
    # https://github.com/rebuy-de/aws-nuke/issues/637
    echo
    echo "Removing Option Groups"
    # List Option Groups
    aws rds describe-option-groups | jq -r '.[] | .[].OptionGroupName' | grep -v "default"
    echo
    # Remove Option Groups
    aws rds describe-option-groups | jq -r '.[] | .[].OptionGroupName' | grep -v "default" | xargs -I '{}' aws rds delete-option-group --option-group-name "{}"
    # ----

  done



done < temp/accounts.txt

echo
echo "Nuke Operation copmpleted"
echo