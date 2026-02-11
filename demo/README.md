# EIP-8004 Trustless Agents Demo

This directory contains a **simple demo script** that demonstrates the core flow of the [EIP-8004 Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004) protocol on Sui Devnet.

## Protocol Overview (EIP-8004)

- **Agent registration and discovery**: On-chain registration of agent metadata, capabilities, and communication endpoints
- **Trust model**: Reputation, stake/zkML validation, TEE attestation
- **Agent NFT**: NFT representing agent ownership (object model on Sui)
- **Reputation system**: On-chain ratings and aggregation

## Demo Flow

The script runs the following steps in order (creating objects when IDs are not provided):

| Step | Description |
|------|-------------|
| 1 | **init_registry** — Initialize the global registry (shared object) |
| 2 | **init_stake_pool** — Initialize the stake pool (shared object) |
| 3 | **create_agent** — Create an Agent NFT (name, description, image) |
| 4 | **register_agent** — Register the agent (capabilities, endpoints, trust model) — Currently a placeholder; full flow requires BCS serialization |
| 5 | **create_agent_reputation** — Create a reputation object for the agent |
| 6 | **add_rating** — Add a rating (1–10 score + category) |

## Prerequisites

1. **Contract deployed to Devnet**  
   From the project root:
   ```bash
   sui client switch --env devnet
   sui client faucet
   cd trustless-agents
   sui client test-publish --gas-budget 100000000 --build-env testnet --pubfile-path Pub.devnet.toml
   ```
   Note the `published-at` in `Pub.devnet.toml` (this is your `PACKAGE_ID`).

2. **Node.js 18+**  
   Have `node` and `npm` installed.

## Usage

```bash
cd demo
cp .env.example .env
# Edit .env: set PACKAGE_ID at minimum; optionally REGISTRY_ID, STAKE_POOL_ID if already inited; optional DEMO_PRIVATE_KEY
npm install
npm run demo
```

- **Without `DEMO_PRIVATE_KEY`**: The script uses a random keypair; that address has no SUI on devnet and will fail with "No valid gas coins". Use a private key for an address that has received faucet SUI (e.g. export with `sui keytool export --key-identity <addr>` and put in `.env`), or run `sui client faucet` and export the active address’s private key into `.env`.
- **Dry run (no transactions)**: `DRY_RUN=1 npm run demo` (no gas required).

## Environment Variables

| Variable | Description |
|----------|-------------|
| `NETWORK` | Network: `devnet` / `testnet` / `mainnet`; default `devnet` |
| `PACKAGE_ID` | Deployed trustless_agents package ID |
| `REGISTRY_ID` | Existing Registry object ID (optional; if unset, init_registry is run) |
| `STAKE_POOL_ID` | Existing StakePool object ID (optional; if unset, init_stake_pool is run) |
| `DEMO_PRIVATE_KEY` | Private key for the demo (optional; random keypair if unset) |
| `DRY_RUN` | Set to `1` to build transactions without sending them |

## Full register_agent and CLI Example

`register_agent` expects complex arguments (capability list, endpoint list, trust model, etc.); the script currently uses a placeholder. For a full call, see:

- **DEPLOYMENT.md** in the repo for TypeScript/BCS examples
- Or use Sui CLI with pre-encoded capabilities/endpoints

Example: after creating an Agent NFT, register via CLI (replace `<PACKAGE_ID>`, `<REGISTRY_ID>`, `<AGENT_NFT_ID>` with real values):

```bash
# After creating the Agent NFT you get AGENT_NFT_ID; then call register_agent via SDK or CLI
sui client call --package <PACKAGE_ID> --module agent_registry --function register_agent \
  --args <REGISTRY_ID> <AGENT_NFT_ID> ... # remaining args must be BCS-encoded
```

## Links

- [EIP-8004: Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004)
- [Sui TypeScript SDK](https://sdk.mystenlabs.com/sui)
- Project root **README.md**, **DEPLOYMENT.md**
