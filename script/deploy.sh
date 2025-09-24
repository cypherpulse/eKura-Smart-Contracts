#!/bin/bash

echo "🚀 eKura Smart Contract Deployment"
echo "=================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to deploy to a specific network
deploy_to_network() {
    local network=$1
    echo -e "${YELLOW}Deploying to $network...${NC}"
    
    case $network in
        "local")
            echo "Starting local Anvil node..."
            anvil &
            ANVIL_PID=$!
            sleep 2
            forge script script/DeployElectionFactory.s.sol --rpc-url http://localhost:8545 --broadcast
            kill $ANVIL_PID
            ;;
        "base-sepolia")
            forge script script/DeployElectionFactory.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify
            ;;
        "eth-sepolia")
            forge script script/DeployElectionFactory.s.sol --rpc-url $ETH_SEPOLIA_RPC_URL --broadcast --verify
            ;;
        *)
            echo -e "${RED}Unknown network: $network${NC}"
            echo "Available networks: local, base-sepolia, eth-sepolia"
            exit 1
            ;;
    esac
}

# Check if network argument is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Please specify a network${NC}"
    echo "Usage: ./scripts/deploy.sh <network>"
    echo "Available networks: local, base-sepolia, eth-sepolia"
    exit 1
fi

# Deploy to specified network
deploy_to_network $1

echo -e "${GREEN}✅ Deployment completed!${NC}"