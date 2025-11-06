#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Deploying Yeil Token to Local Network${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if .env exists, if not copy from .env.example
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    cp .env.example .env
fi

# Source the .env file
source .env

echo -e "${GREEN}Step 1: Deploying contracts...${NC}"
forge script script/DeployYeil.s.sol:DeployYeil \
    --rpc-url $LOCALHOST_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -vvvv

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${YELLOW}Contract addresses can be found in:${NC}"
echo -e "broadcast/DeployYeil.s.sol/31337/run-latest.json"
echo ""
echo -e "${YELLOW}To verify deployment, run:${NC}"
echo -e "forge script script/DeployYeil.s.sol:DeployYeil --rpc-url \$LOCALHOST_RPC_URL --private-key \$PRIVATE_KEY"
