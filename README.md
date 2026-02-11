# Trustless Agents - Sui Chain Implementation

This is the implementation of EIP-8004: Trustless Agents on the Sui blockchain using Move 2024.

## Project Overview

This project provides a decentralized registration, discovery, and verification mechanism for AI agents, implementing the following core functionalities:

1. **Agent NFT** - Uses Sui's object model as an alternative to ERC-721, representing AI agent ownership
2. **Agent Registry** - Decentralized agent registration system storing agent capabilities and communication endpoints
3. **Reputation System** - Public reputation scoring and rating system
4. **Validation System** - Supports three validation models: staking, zkML, and TEE

## Technical Differences on Sui Chain

### Alternative to ERC-721

On Ethereum, ERC-721 is an account-based NFT standard. On Sui, we use the **object model** to represent NFTs:

- **Ownership**: Sui objects are stored directly under the owner's address, no account mapping needed
- **Composability**: Objects can be passed as parameters, enabling flexible composition
- **Parallelism**: Sui supports object-level parallel execution, improving throughput

### Core Modules

#### 1. Agent NFT (`agent_nft.move`)

```move
public struct AgentNFT has key, store {
    id: UID,
    agent_id: u64,
    name: String,
    description: String,
    image_url: String,
    owner: address,
    created_at: u64,
    version: u64,
}
```

**Features**:
- Create, transfer, and update Agent NFTs
- Supports Display standard for NFT display
- Emits creation, transfer, and update events

#### 2. Agent Registry (`agent_registry.move`)

**Core Structures**:
- `Capability` - Agent capability definition
- `Endpoint` - Communication endpoint configuration
- `TrustModel` - Trust model configuration
- `AgentRegistration` - Agent registration information
- `Registry` - Global registry

**Features**:
- Register agents and their capabilities
- Manage communication endpoints (supports MCP, A2A, etc.)
- Configure trust models (reputation, staking, zkML, TEE)
- Search agents by protocol and capability

#### 3. Reputation System (`reputation_system.move`)

**Core Structures**:
- `Rating` - Individual rating record
- `AgentReputation` - Agent reputation data

**Features**:
- Add and update ratings (1-10 scale)
- Rate by category (performance, reliability, security, user_experience)
- Calculate average scores
- Query rating history and specific reviewer ratings

#### 4. Validation System (`validation_system.move`)

**Core Structures**:
- `StakeInfo` - Staking information
- `ZkmlProof` - zkML verification proof
- `TeeAttestation` - TEE attestation
- `AgentValidation` - Validation data
- `StakePool` - Staking pool

**Features**:
- Stake/unstake SUI tokens
- Add zkML zero-knowledge proofs
- Add TEE trusted execution environment attestations
- Query validation status and types

## Project Structure

```
trustless-agents/
├── sources/
│   ├── agent_nft.move          # Agent NFT implementation
│   ├── agent_registry.move     # Agent registration system
│   ├── reputation_system.move  # Reputation system
│   └── validation_system.move  # Validation system
├── tests/
│   └── (test files)
├── Move.toml                   # Move project configuration
└── README.md                   # Project documentation
```

## Installation and Build

### Prerequisites

- Sui CLI tools
- Move 2024 compiler

### Build Project

```bash
sui move build
```

### Run Tests

```bash
sui move test
```

单元测试位于 `tests/` 目录：
- `agent_nft_tests.move`：创建/更新/转移 Agent NFT、get_agent_info、is_owner
- `agent_registry_tests.move`：init_registry、get_registry_stats
- `reputation_system_tests.move`：create_agent_reputation、add_rating、get_reputation_stats，以及无效评分 (0/11) 的 expected_failure
- `validation_system_tests.move`：init_stake_pool、create_agent_validation、is_validated

## EIP-8004 协议演示 (Demo)

在 `demo/` 目录下提供了基于 TypeScript + Sui SDK 的**简单演示脚本**，用于在 Devnet 上跑通协议流程：初始化注册表与质押池、创建 Agent NFT、创建声誉、添加评分等。

```bash
cd demo
cp .env.example .env   # 填写 PACKAGE_ID 等
npm install
npm run demo
```

详见 [demo/README.md](demo/README.md)。

## Deployment

### 1. Publish Package

```bash
sui client publish --gas-budget 100000000
```

### 2. Initialize Shared Objects

After deployment, initialize the following shared objects:

```bash
# Initialize global registry
sui client call --package <PACKAGE_ID> \
  --module agent_registry \
  --function init_registry \
  --gas-budget 10000000

# Initialize staking pool
sui client call --package <PACKAGE_ID> \
  --module validation_system \
  --function init_stake_pool \
  --gas-budget 10000000
```

### 3. Create Agent

```bash
# Create Agent NFT
sui client call --package <PACKAGE_ID> \
  --module agent_nft \
  --function create_agent \
  --args 1 "My Agent" "Description" "https://image.url" \
  --gas-budget 10000000
```

### 4. Register Agent

```bash
# Register agent (requires preparing capabilities and endpoints data)
sui client call --package <PACKAGE_ID> \
  --module agent_registry \
  --function register_agent \
  --args <REGISTRY_ID> <AGENT_NFT_ID> <CAPABILITIES> <ENDPOINTS> \
        <ENS_NAME> <TRUST_MODEL> <METADATA_HASH> \
  --gas-budget 10000000
```

## Usage Examples

### Create a Complete Agent

```bash
# 1. Create Agent NFT
sui client call --package <PACKAGE_ID> \
  --module agent_nft \
  --function create_agent \
  --args 1 "Code Assistant" "AI coding helper" "https://agent.image" \
  --gas-budget 10000000

# 2. Create reputation data
sui client call --package <PACKAGE_ID> \
  --module reputation_system \
  --function create_agent_reputation \
  --args <AGENT_REGISTRATION_ID> <OWNER_ADDRESS> \
  --gas-budget 10000000

# 3. Create validation data
sui client call --package <PACKAGE_ID> \
  --module validation_system \
  --function create_agent_validation \
  --args <AGENT_REGISTRATION_ID> <OWNER_ADDRESS> \
  --gas-budget 10000000

# 4. Add stake (optional)
sui client call --package <PACKAGE_ID> \
  --module validation_system \
  --function add_stake \
  --args <STAKE_POOL_ID> <VALIDATION_ID> <COIN_ID> 0 \
  --gas-budget 10000000

# 5. Rate agent
sui client call --package <PACKAGE_ID> \
  --module reputation_system \
  --function add_rating \
  --args <REPUTATION_ID> 9 "Great agent!" "performance" \
  --gas-budget 10000000
```

## API Queries

### Query Agent Information

```bash
sui client object <AGENT_NFT_ID>
```

### Query Registration Information

```bash
sui client dynamic-field <REGISTRY_ID>
```

### Query Reputation Stats

```bash
sui client object <REPUTATION_ID>
```

### Query Validation Status

```bash
sui client object <VALIDATION_ID>
```

## Event Monitoring

All modules emit events that can be used to build indexers:

- `AgentCreated` - Agent creation event
- `AgentTransferred` - Agent transfer event
- `AgentRegistered` - Agent registration event
- `RatingAdded` - Rating addition event
- `Staked` - Staking event
- `ZkmlProofAdded` - zkML proof addition event
- `TeeAttestationAdded` - TEE attestation addition event

## Security Considerations

1. **Ownership Verification**: All update operations verify the owner's identity
2. **Stake Lockup**: Staked tokens have a lockup period
3. **Rating Limits**: Rating range is limited to 1-10 points
4. **Immutability**: On-chain data cannot be deleted, ensuring audit trail integrity

## Future Improvements

- [ ] Add batch operation support
- [ ] Implement agent marketplace trading functionality
- [ ] Integrate more validation protocols
- [ ] Add agent version control
- [ ] Implement agent-to-agent communication protocols
- [ ] Add agent performance monitoring

## Related Resources

- [EIP-8004: Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004)
- [Sui Move Official Documentation](https://docs.sui.io/)
- [Sui Object Model](https://docs.sui.io/concepts/object-model)

## License

This project follows the MIT License.

## Contributing

Issues and Pull Requests are welcome!

## Contact

For questions or suggestions, please submit an Issue or contact the project maintainers.