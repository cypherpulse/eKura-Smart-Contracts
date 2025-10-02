# Foundry Commands Reference for eKura Smart Contracts

## Table of Contents
- [Installation](#installation)
- [Project Setup](#project-setup)
- [Compilation](#compilation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Anvil Local Node](#anvil-local-node)
- [Cast Utilities](#cast-utilities)
- [Forge Utilities](#forge-utilities)
- [Gas Optimization](#gas-optimization)
- [Verification](#verification)
- [Debug & Troubleshooting](#debug--troubleshooting)

## Installation

### Install Foundry
```bash
# Install Foundry (Unix/Linux/macOS)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Windows (using Git Bash or WSL)
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Update Foundry
```bash
foundryup
```

### Check Installation
```bash
forge --version
cast --version
anvil --version
chisel --version
```

## Project Setup

### Initialize New Project
```bash
forge init eKura-Smart-Contracts
cd eKura-Smart-Contracts
```

### Install Dependencies
```bash
# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable

# Install forge-std (testing utilities)
forge install foundry-rs/forge-std

# Update dependencies
forge update
```

### Clean Build Artifacts
```bash
forge clean
```

## Compilation

### Basic Compilation
```bash
# Compile all contracts
forge build

# Compile with specific Solidity version
forge build --use 0.8.20

# Compile with via-IR (for stack too deep issues)
forge build --via-ir

# Compile with optimization
forge build --optimize --optimizer-runs 200
```

### Check Contract Size
```bash
forge build --sizes
```

## Testing

### Run All Tests
```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -v      # Show test results
forge test -vv     # Show test results + console.log output
forge test -vvv    # Show test results + console.log + stack traces for failing tests
forge test -vvvv   # Show test results + console.log + stack traces + setup traces

# Run specific test file
forge test --match-path test/unit/ElectionFactoryTest.t.sol

# Run specific test function
forge test --match-test test_CreateElection_Success

# Run tests for specific contract
forge test --match-contract ElectionFactoryTest

# Run tests for specific contract with detailed output
forge test --match-contract ElectionFactoryTest -vv

# Combine filters for precise testing
forge test --match-contract ElectionFactoryTest --match-test test_AddOrgAdmin -vv
```

### Gas Reporting
```bash
# Run tests with gas reporting
forge test --gas-report

# Save gas report to file
forge test --gas-report > gas-report.txt
```

### Coverage Analysis
```bash
# Generate coverage report
forge coverage

# Generate coverage with IR minimum (for stack too deep)
forge coverage --ir-minimum

# Generate detailed coverage report
forge coverage --report lcov
```

### Test Filtering & Verbosity

#### Verbosity Levels Explained
- **`-v`**: Shows only test results (pass/fail)
- **`-vv`**: Shows test results + `console.log()` output from your tests
- **`-vvv`**: Shows test results + console.log + stack traces for failing tests
- **`-vvvv`**: Shows test results + console.log + stack traces + setup traces

#### Filtering Options
```bash
# Match by contract name
forge test --match-contract ElectionFactoryTest -vv

# Match by test function name
forge test --match-test test_AddOrgAdmin -vv

# Match by file path
forge test --match-path test/unit/ -vv

# Combine multiple filters
forge test --match-contract ElectionFactoryTest --match-test test_CreateElection -vv

# Exclude specific tests
forge test --no-match-test test_ExpensiveFunction
```

#### When to Use Each Verbosity Level
- **`-v`**: Quick test runs to see pass/fail status
- **`-vv`**: Development & debugging (most common) - shows your console.log statements
- **`-vvv`**: Investigating test failures - shows stack traces
- **`-vvvv`**: Deep debugging - shows complete execution traces

### Fork Testing
```bash
# Test against forked mainnet
forge test --fork-url https://eth-mainnet.alchemyapi.io/v2/YOUR_KEY

# Test against specific block
forge test --fork-url $ETH_RPC_URL --fork-block-number 18000000
```

## Deployment

### Local Deployment (Anvil)
```bash
# Deploy to local Anvil node
forge script script/DeployElectionFactory.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast

# Deploy with verification simulation
forge script script/DeployElectionFactory.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -v
```

### Testnet Deployment
```bash
# Deploy to Base Sepolia
forge script script/DeployElectionFactory.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY

# Deploy to Ethereum Sepolia
forge script script/DeployElectionFactory.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

### Mainnet Deployment
```bash
# Deploy to Base Mainnet
forge script script/DeployElectionFactory.s.sol --rpc-url $BASE_MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY

# Deploy to Ethereum Mainnet
forge script script/DeployElectionFactory.s.sol --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

### Dry Run Deployment
```bash
# Simulate deployment without broadcasting
forge script script/DeployElectionFactory.s.sol --rpc-url $RPC_URL
```

## Anvil Local Node

### Start Anvil
```bash
# Start with default settings
anvil

# Start with specific block time
anvil --block-time 2

# Start with specific number of accounts
anvil --accounts 20

# Start with custom gas limit
anvil --gas-limit 30000000

# Fork from mainnet
anvil --fork-url $ETH_RPC_URL

# Fork from specific block
anvil --fork-url $ETH_RPC_URL --fork-block-number 18000000

# Start with specific chain ID
anvil --chain-id 1337
```

### Anvil Accounts
```bash
# Show accounts and private keys
anvil --accounts 10 --show-private-keys
```

## Cast Utilities

### Account Management
```bash
# Create new wallet
cast wallet new

# Import wallet from private key
cast wallet import testnet --interactive

# Get wallet address from private key
cast wallet address --private-key $PRIVATE_KEY
```

### Blockchain Queries
```bash
# Get latest block number
cast block-number --rpc-url $RPC_URL

# Get balance
cast balance 0x742d35Cc64532aAE8C686D7f3CE0DE6bf5ae8F64 --rpc-url $RPC_URL

# Get nonce
cast nonce 0x742d35Cc64532aAE8C686D7f3CE0DE6bf5ae8F64 --rpc-url $RPC_URL

# Get transaction receipt
cast receipt 0x... --rpc-url $RPC_URL

# Get contract code
cast code 0x... --rpc-url $RPC_URL
```

### Contract Interactions
```bash
# Call read function
cast call 0x... "getTotalElections()" --rpc-url $RPC_URL

# Call with parameters
cast call 0x... "getElection(uint256)" 1 --rpc-url $RPC_URL

# Send transaction
cast send 0x... "addOrgAdmin(uint256,address)" 1 0x... --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Estimate gas
cast estimate 0x... "createElection(...)" --rpc-url $RPC_URL
```

### Utility Functions
```bash
# Convert units
cast to-wei 1 ether
cast from-wei 1000000000000000000

# Encode function call
cast calldata "createElection(uint256,string,string,uint256,uint256,string[])" 1 "Election" "Description" 1234567890 1234567891 '["Alice","Bob"]'

# Decode transaction data
cast --calldata-decode "transfer(address,uint256)" 0x...

# Generate random hex
cast random
```

## Forge Utilities

### Code Formatting
```bash
# Format code
forge fmt

# Check formatting without changing files
forge fmt --check
```

### Generate Documentation
```bash
# Generate documentation
forge doc

# Build and serve documentation
forge doc --build --serve
```

### Create Project Structure
```bash
# Create new contract file
forge create-contract src/NewContract.sol

# Create new test file
forge create-test test/NewContractTest.t.sol
```

### Inspection Tools
```bash
# Generate storage layout
forge inspect src/ElectionFactory.sol:ElectionFactory storage-layout

# Generate ABI
forge inspect src/ElectionFactory.sol:ElectionFactory abi

# Generate bytecode
forge inspect src/ElectionFactory.sol:ElectionFactory bytecode

# Generate method identifiers
forge inspect src/ElectionFactory.sol:ElectionFactory methods
```

## Gas Optimization

### Gas Analysis
```bash
# Profile gas usage
forge test --gas-report

# Generate gas snapshot
forge snapshot

# Compare gas snapshots
forge snapshot --diff .gas-snapshot

# Check gas for specific function
forge test --match-test test_CreateElection_Success --gas-report
```

### Optimization Commands
```bash
# Build with different optimization levels
forge build --optimizer-runs 1
forge build --optimizer-runs 200
forge build --optimizer-runs 1000000

# Use via-IR for optimization
forge build --via-ir --optimizer-runs 200
```

## Verification

### Contract Verification
```bash
# Verify on Etherscan
forge verify-contract 0x... src/ElectionFactory.sol:ElectionFactory --etherscan-api-key $ETHERSCAN_API_KEY --chain-id 1

# Verify on Basescan
forge verify-contract 0x... src/ElectionFactory.sol:ElectionFactory --etherscan-api-key $BASESCAN_API_KEY --chain-id 8453

# Verify with constructor arguments
forge verify-contract 0x... src/ElectionFactory.sol:ElectionFactory --constructor-args $(cast abi-encode "constructor(address)" 0x...) --etherscan-api-key $ETHERSCAN_API_KEY
```

### Check Verification Status
```bash
# Check if contract is verified
cast interface 0x... --rpc-url $RPC_URL
```

## Debug & Troubleshooting

### Debug Transactions
```bash
# Debug failed transaction
forge debug --rpc-url $RPC_URL 0x...

# Trace transaction execution
cast run 0x... --rpc-url $RPC_URL --debug
```

### Stack Trace
```bash
# Get detailed stack trace for failed tests
forge test --match-test test_FailingTest -vvvv
```

### Common Issues & Solutions

#### Stack Too Deep Error
```bash
# Use via-IR compilation
forge build --via-ir

# For coverage with stack too deep
forge coverage --ir-minimum
```

#### Memory Issues
```bash
# Increase memory limit
export FOUNDRY_MEMORY_LIMIT=4000
forge test
```

#### Slow Compilation
```bash
# Compile with fewer optimizer runs
forge build --optimizer-runs 1

# Clean and rebuild
forge clean && forge build
```

## Environment Variables

Create a `.env` file with the following variables:

```bash
# Private Keys (NEVER commit these)
PRIVATE_KEY=0x...
DEPLOYER_PRIVATE_KEY=0x...

# RPC URLs
ETH_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your-key
BASE_MAINNET_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-key

# API Keys
ETHERSCAN_API_KEY=your-etherscan-key
BASESCAN_API_KEY=your-basescan-key
```

## Quick Reference Commands

```bash
# Development workflow
forge clean && forge build && forge test

# Deploy to local testnet
anvil & # Start in background
forge script script/DeployElectionFactory.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# Get coverage report
forge coverage --ir-minimum

# Format and test
forge fmt && forge test

# Build with optimization
forge build --via-ir --optimizer-runs 200
```

## Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Standard Library](https://github.com/foundry-rs/forge-std)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)