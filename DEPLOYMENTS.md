# 🚀 eKura Smart Contracts - Deployment Information

This document contains deployment information for all eKura smart contracts across different networks.

## 📋 Table of Contents

- [Overview](#overview)
- [Base Sepolia Testnet](#base-sepolia-testnet)
- [Ethereum Sepolia Testnet](#ethereum-sepolia-testnet)
- [Mainnet Deployments](#mainnet-deployments)
- [Contract Verification](#contract-verification)
- [Deployment Scripts](#deployment-scripts)
- [Testing Guide](#testing-guide)

---

## 🎯 Overview

eKura is a decentralized voting platform with multi-chain support. The system consists of two main contracts:

- **ElectionFactory**: Creates and manages elections for organizations
- **VoteStorage**: Handles vote storage, counting, and meta-transactions (upgradeable)

### 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐
│  ElectionFactory │    │   VoteStorage    │
│                 │    │     (Proxy)      │
│  - Create       │───▶│  - Store Votes   │
│    Elections    │    │  - Count Votes   │
│  - Manage Orgs  │    │  - Meta-Txs      │
│  - Admin        │    │  - Upgradeable   │
└─────────────────┘    └──────────────────┘
```

---

## 🔵 Base Sepolia Testnet

### Deployment Information
- **Date**: October 2, 2025
- **Deployer**: `0xC5983E0B551a7C60D62177CcCadf199b9EeAC54b`
- **Total Gas Used**: 2,869,418 gas
- **Total Cost**: 0.000246 ETH (~$0.60)
- **Block**: 31961818-31961819

### Contract Addresses

| Contract | Address | Type | Verified |
|----------|---------|------|----------|
| **ElectionFactory** | [`0x33F5e3b399f66f1934c7A2496Ad98eD3C5f18032`](https://sepolia.basescan.org/address/0x33F5e3b399f66f1934c7A2496Ad98eD3C5f18032) | Implementation |  ✅ Verified |
| **VoteStorage Proxy** | [`0xf3948ACFa07BdDF81200d4A143ADeA1815f5Bf22`](https://sepolia.basescan.org/address/0xf3948ACFa07BdDF81200d4A143ADeA1815f5Bf22) | ERC1967 Proxy | ⏳ Pending |
| **VoteStorage Implementation** | [`0xaDCA0f4Da058A637aeb4B8146C98b83f8355795e`](https://sepolia.basescan.org/address/0xaDCA0f4Da058A637aeb4B8146C98b83f8355795e) | Implementation |  ✅ Verified  |

### Transaction Hashes
- **ElectionFactory**: `0x98e50bc5eb256facb4ae274d3879c37b9cdbd05d5ffefcfdfb756c88226c5eeb`
- **VoteStorage Proxy**: `0x5c35e3d59e3f8c12c25595c30c2b99dc02cb171333598718b0c786a882b4f865`
- **VoteStorage Implementation**: `0xb8dc248a60f13b9468317a8de222c3fac3da37155cf90f9781d4868375800e9a`

### Network Details
- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet

---

## 🔷 Ethereum Sepolia Testnet

### Deployment Information
- **Date**: October 2, 2025
- **Deployer**: `0xC5983E0B551a7C60D62177CcCadf199b9EeAC54b`
- **Total Gas Used**: 2,869,418 gas
- **Total Cost**: 0.000002869 ETH (~$0.007)
- **Block**: 9350432

### Contract Addresses

| Contract | Address | Type | Verified |
|----------|---------|------|----------|
| **ElectionFactory** | [`0x2cd2a92088FC452526aE0ac2eB73Fa212866178F`](https://sepolia.etherscan.io/address/0x2cd2a92088FC452526aE0ac2eB73Fa212866178F) | Implementation |  ✅ Verified  |
| **VoteStorage Proxy** | [`0x5c1EE6918b48f148A4B88E8B9Ca258da44f2f764`](https://sepolia.etherscan.io/address/0x5c1EE6918b48f148A4B88E8B9Ca258da44f2f764) | ERC1967 Proxy |  ✅ Verified  |
| **VoteStorage Implementation** | [`0x218b73a84d9D463696Ccf39D926B724d774c184D`](https://sepolia.etherscan.io/address/0x218b73a84d9D463696Ccf39D926B724d774c184D) | Implementation | ⏳ Pending |

### Transaction Hashes
- **ElectionFactory**: `0x95e5ea6abbda577234a5ca828c6d7b5cb343658837e00084102df39707b8b68d`
- **VoteStorage Proxy**: `0xc3744462d94ebb32bf50964234426f8c498c6606537ca5f14df7c5dcaf2a76ee`
- **VoteStorage Implementation**: `0x46d32915d5a692930eef132adf37efe6bba86774e87ff8783b893f452662acbb`

### Network Details
- **Chain ID**: 11155111
- **RPC URL**: https://ethereum-sepolia-rpc.publicnode.com
- **Explorer**: https://sepolia.etherscan.io
- **Faucet**: https://sepoliafaucet.com

---

## 🌐 Mainnet Deployments

> 🚧 **Coming Soon**: Mainnet deployments will be added after testnet validation.

### Base Mainnet
- **Status**: Not Deployed
- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Explorer**: https://basescan.org

### Ethereum Mainnet
- **Status**: Not Deployed
- **Chain ID**: 1
- **RPC URL**: https://mainnet.infura.io/v3/YOUR_KEY
- **Explorer**: https://etherscan.io

---

## 🔍 Contract Verification

### Verification Status

| Network | ElectionFactory | VoteStorage Implementation | Notes |
|---------|----------------|---------------------------|-------|
| Base Sepolia | ⏳ Pending | ⏳ Pending | API key issues |
| Ethereum Sepolia | ⏳ Pending | ⏳ Pending | API key issues |

### Manual Verification Commands

#### Base Sepolia
```bash
# ElectionFactory
forge verify-contract \
  0x33F5e3b399f66f1934c7A2496Ad98eD3C5f18032 \
  src/ElectionFactory.sol:ElectionFactory \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY

# VoteStorage Implementation
forge verify-contract \
  0xaDCA0f4Da058A637aeb4B8146C98b83f8355795e \
  src/VoteStorage.sol:VoteStorage \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY
```

#### Ethereum Sepolia
```bash
# ElectionFactory
forge verify-contract \
  0x2cd2a92088FC452526aE0ac2eB73Fa212866178F \
  src/ElectionFactory.sol:ElectionFactory \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY

# VoteStorage Implementation
forge verify-contract \
  0x218b73a84d9D463696Ccf39D926B724d774c184D \
  src/VoteStorage.sol:VoteStorage \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

---

## 📜 Deployment Scripts

### Available Scripts

| Script | Purpose | Networks |
|--------|---------|----------|
| `Deploy.s.sol` | Main deployment script with auto-detection | All |
| `DeployBaseSepolia.s.sol` | Base Sepolia specific deployment | Base Sepolia |
| `DeployEthSepolia.s.sol` | Ethereum Sepolia specific deployment | Ethereum Sepolia |
| `CreateSampleElection.s.sol` | Create test elections post-deployment | All |

### Deployment Commands

#### Base Sepolia
```bash
forge script script/DeployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --via-ir
```

#### Ethereum Sepolia
```bash
forge script script/DeployEthSepolia.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --via-ir
```

---

## 🧪 Testing Guide

### Testing Deployed Contracts

#### Check Contract Status
```bash
# Base Sepolia - Check ElectionFactory
cast call 0x33F5e3b399f66f1934c7A2496Ad98eD3C5f18032 \
  "getPlatformAdmin()" \
  --rpc-url https://sepolia.base.org

# Base Sepolia - Check VoteStorage
cast call 0xf3948ACFa07BdDF81200d4A143ADeA1815f5Bf22 \
  "getElectionFactory()" \
  --rpc-url https://sepolia.base.org

# Ethereum Sepolia - Check ElectionFactory
cast call 0x2cd2a92088FC452526aE0ac2eB73Fa212866178F \
  "getPlatformAdmin()" \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# Ethereum Sepolia - Check VoteStorage
cast call 0x5c1EE6918b48f148A4B88E8B9Ca258da44f2f764 \
  "getElectionFactory()" \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

#### Create Sample Elections
```bash
# Base Sepolia
forge script script/CreateSampleElection.s.sol \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --via-ir \
  --sig "run(address,address)" \
  0x33F5e3b399f66f1934c7A2496Ad98eD3C5f18032 \
  0xf3948ACFa07BdDF81200d4A143ADeA1815f5Bf22

# Ethereum Sepolia
forge script script/CreateSampleElection.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --via-ir \
  --sig "run(address,address)" \
  0x2cd2a92088FC452526aE0ac2eB73Fa212866178F \
  0x5c1EE6918b48f148A4B88E8B9Ca258da44f2f764
```

### Running Local Tests
```bash
# Run all tests
forge test --via-ir -vv

# Run specific test suites
forge test --match-contract ElectionFactoryTest --via-ir -vv
forge test --match-contract VoteStorageTest --via-ir -vv
forge test --match-contract InteractionTest --via-ir -vv
```

---

## 📊 Cost Comparison

| Network | Deployment Cost | Gas Price | Use Case |
|---------|----------------|-----------|----------|
| **Base Sepolia** | 0.000246 ETH (~$0.60) | ~0.2 gwei | Fast, cheap transactions |
| **Ethereum Sepolia** | 0.000002869 ETH (~$0.007) | ~0.001 gwei | High security, slower |

---

## 🔗 Important Links

### Documentation
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/)
- [Base Documentation](https://docs.base.org/)

### Block Explorers
- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Ethereum Sepolia Explorer](https://sepolia.etherscan.io/)

### Faucets
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
- [Ethereum Sepolia Faucet](https://sepoliafaucet.com/)

---

## 📝 Notes

- All contracts use Solidity ^0.8.20
- VoteStorage uses OpenZeppelin's upgradeable proxy pattern
- Contracts follow Cyfrin Updraft coding standards
- Multi-signature support for production deployments recommended
- Consider using a multisig wallet for mainnet deployments

---

## 🎯 Next Steps

1. **Verify Contracts**: Complete contract verification on block explorers
2. **Testing**: Comprehensive testing on both testnets
3. **Frontend Integration**: Connect frontend to deployed contracts
4. **Mainnet Deployment**: Deploy to production networks
5. **Monitoring**: Set up contract monitoring and analytics

---

**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Author**: cypherpulse.base.eth 
**Repository**: [eKura-Smart-Contracts](https://github.com/cypherpulse/eKura-Smart-Contracts)
