# eKura Deployment Commands

## Local Deployment (Anvil)
```bash
# Start local blockchain
anvil

# Deploy both contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Create sample election
forge script script/CreateSampleElection.s.sol --rpc-url http://localhost:8545 --broadcast --sig "run(address,address)" <ELECTION_FACTORY_ADDRESS> <VOTE_STORAGE_ADDRESS>



# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify

# Create sample election
forge script script/CreateSampleElection.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --sig "run(address,address)" <ELECTION_FACTORY_ADDRESS> <VOTE_STORAGE_ADDRESS>

# Deploy to Ethereum Sepolia
forge script script/Deploy.s.sol --rpc-url $ETH_SEPOLIA_RPC_URL --broadcast --verify