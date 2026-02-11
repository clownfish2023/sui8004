/**
 * EIP-8004 contract addresses and transaction builders for the demo app.
 * VITE_PACKAGE_ID and VITE_NETWORK are set at build time (see .env.example).
 */

const PACKAGE_ID = import.meta.env.VITE_PACKAGE_ID ?? "0x94a476f4b925efb03bb04f0e8e88ba9a8533ec197f6d20cd510995ad2d3a07d8";
export const NETWORK = (import.meta.env.VITE_NETWORK ?? "devnet") as "devnet" | "testnet" | "mainnet";

export function getPackageId() {
  return PACKAGE_ID;
}

export const CONTRACT = {
  agentRegistry: `${PACKAGE_ID}::agent_registry`,
  agentNft: `${PACKAGE_ID}::agent_nft`,
  reputationSystem: `${PACKAGE_ID}::reputation_system`,
  validationSystem: `${PACKAGE_ID}::validation_system`,
} as const;
