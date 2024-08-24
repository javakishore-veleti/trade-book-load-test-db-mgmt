#!/bin/bash
# Script to install or upgrade Liquibase on remote AWS EC2 Ubuntu machines or local environments

# Check for environment argument
if [ -z "$1" ]; then
  echo "Please provide an environment (e.g., dev, qa, prod-us, local-dev, etc.)"
  exit 1
fi

ENV=$1
EC2_HOSTS=$2

# Define the path to the JSON file containing EC2 IP addresses and versions
JSON_FILE="ec2-instances.json"

# Check if jq is installed (for parsing JSON)
if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed. Installing jq..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install jq
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get install jq -y
  fi
fi

# Function to install or upgrade Liquibase on a remote EC2 instance
install_or_upgrade_liquibase_remote() {
  IP=$1
  VERSION=$2
  MAKE_IT_LATEST=$3

  echo "Checking Liquibase installation on EC2 instance $IP..."

  ssh -o "StrictHostKeyChecking=no" ubuntu@$IP << EOF
    # Check current Liquibase version
    CURRENT_VERSION=\$(liquibase --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "")

    if [ "\$CURRENT_VERSION" != "$VERSION" ]; then
      echo "Current version (\$CURRENT_VERSION) is not the intended version ($VERSION). Installing or upgrading Liquibase..."
      
      # Remove any existing Liquibase version
      sudo rm -rf /usr/local/bin/liquibase*

      # Install the intended Liquibase version
      LIQUIBASE_URL="https://github.com/liquibase/liquibase/releases/download/v$VERSION/liquibase-$VERSION.zip"
      wget \$LIQUIBASE_URL -O liquibase.zip
      unzip liquibase.zip -d liquibase-$VERSION
      sudo mv liquibase-$VERSION /usr/local/bin/
      rm liquibase.zip

      # Set symbolic link if make-it-latest is true
      if [ "$MAKE_IT_LATEST" == "true" ]; then
        sudo ln -sfn /usr/local/bin/liquibase-$VERSION /usr/local/bin/liquibase
        echo "Set Liquibase $VERSION as the current version."
      fi
    else
      echo "Liquibase $VERSION is already installed and up-to-date."
    fi
EOF
}

# Function to install or upgrade Liquibase on a local machine
install_or_upgrade_liquibase_local() {
  VERSION=$1
  MAKE_IT_LATEST=$2
  OS=$3

  echo "Installing Liquibase on local machine ($OS)..."

  # Check current Liquibase version
  CURRENT_VERSION=$(liquibase --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "")

  if [ "$CURRENT_VERSION" != "$VERSION" ]; then
    echo "Current version ($CURRENT_VERSION) is not the intended version ($VERSION). Installing or upgrading Liquibase..."

    # Remove any existing Liquibase version
    sudo rm -rf /usr/local/bin/liquibase*

    # Install the intended Liquibase version
    LIQUIBASE_URL="https://github.com/liquibase/liquibase/releases/download/v$VERSION/liquibase-$VERSION.zip"
    wget $LIQUIBASE_URL -O liquibase.zip
    unzip liquibase.zip -d liquibase-$VERSION
    sudo mv liquibase-$VERSION /usr/local/bin/
    rm liquibase.zip

    # Set symbolic link if make-it-latest is true
    if [ "$MAKE_IT_LATEST" == "true" ]; then
      sudo ln -sfn /usr/local/bin/liquibase-$VERSION /usr/local/bin/liquibase
      echo "Set Liquibase $VERSION as the current version."
    fi
  else
    echo "Liquibase $VERSION is already installed and up-to-date."
  fi
}

# If specific EC2 hosts are provided, split them into an array
if [ ! -z "$EC2_HOSTS" ]; then
  IFS=',' read -r -a IP_ARRAY <<< "$EC2_HOSTS"
else
  # Otherwise, get the entire configuration for the environment
  ENV_CONFIG=$(jq --arg env "$ENV" '.[$env][]' $JSON_FILE)

  # Extract all IPs for the environment
  IP_ARRAY=($(echo "$ENV_CONFIG" | jq -r '.ip'))
fi

# Loop through each EC2 instance configuration
for IP in "${IP_ARRAY[@]}"; do
  INSTANCE_CONFIG=$(jq --arg env "$ENV" --arg ip "$IP" '.[$env][] | select(.ip == $ip)' $JSON_FILE)
  VERSION=$(echo $INSTANCE_CONFIG | jq -r '.version')
  MAKE_IT_LATEST=$(echo $INSTANCE_CONFIG | jq -r '.make-it-latest')
  OS=$(echo $INSTANCE_CONFIG | jq -r '.os // empty')

  if [ "$IP" == "127.0.0.1" ]; then
    # Local installation
    install_or_upgrade_liquibase_local "$VERSION" "$MAKE_IT_LATEST" "$OS"
  else
    # Remote EC2 installation
    install_or_upgrade_liquibase_remote "$IP" "$VERSION" "$MAKE_IT_LATEST"
  fi
done
