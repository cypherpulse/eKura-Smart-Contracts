# eKura Smart Contract

## Overview

eKura is a decentralized platform for managing university elections, built on Ethereum using Solidity and Foundry. It provides secure, transparent, and auditable election processes for student councils and other university organizations.

## Features

- **Election Factory:** Deploy and manage multiple elections for different organizations.
- **Role-Based Access:** Platform admin and organization admins with granular permissions.
- **Candidate Management:** Flexible candidate lists per election.
- **Event Logging:** Emits events for key actions (election creation, admin management).
- **Upgradeable Architecture:** Uses OpenZeppelin contracts for future proofing.

## Repository Structure

```
.env
.gitignore
foundry.toml
README.md
cache/
lib/
script/
src/
test/
```

- **src/**: Core smart contracts (`ElectionFactory.sol`, `VoteStorage.sol`)
- **script/**: Deployment and configuration scripts
- **test/**: Unit and integration tests (Foundry framework)
- **lib/**: External dependencies (OpenZeppelin, forge-std)

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/)
- Node.js (for OpenZeppelin dependencies)
- An Ethereum node or testnet (e.g., [Anvil](https://book.getfoundry.sh/anvil/))

### Installation

Clone the repository and install dependencies:

```sh
git clone <repo-url>
cd eKura-Smart-Contracts
forge install
```

### Configuration

Set up environment variables in `.env` for deployment keys and network settings.

### Deployment

Use the provided scripts in [script/](script/) for deployment:

```sh
forge script script/DeployElectionFactory.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Running Tests

Unit and integration tests are in [test/unit/](test/unit/) and [test/integration/](test/integration/):

```sh
forge test
```

## Contract Architecture

### ElectionFactory

- Manages organizations and their elections.
- Only platform admin can add/remove organization admins.
- Organization admins can create elections for their organizations.

See [`ElectionFactory`](src/ElectionFactory.sol) for implementation details.

### VoteStorage

- Handles vote recording and tallying.
- Ensures vote integrity and privacy.

See [`VoteStorage`](src/VoteStorage.sol).

## Events

- `ElectionCreated`: Emitted when a new election is created.
- `OrgAdminAdded`: Emitted when an organization admin is added.

## Extending & Contributing

We welcome contributions! Please see [CONTRIBUTING.md](lib/forge-std/CONTRIBUTING.md) for guidelines.

- Fork the repo and create a feature branch.
- Write tests for new features.
- Submit a pull request with a clear description.

## License

This project is licensed under MIT and Apache-2.0. See [LICENSE-MIT](lib/forge-std/LICENSE-MIT) and [LICENSE-APACHE](lib/forge-std/LICENSE-APACHE).

---

_This documentation will be updated as the project evolves. For questions or suggestions, open an issue or contact the maintainers._