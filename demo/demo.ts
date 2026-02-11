/**
 * EIP-8004 Trustless Agents 协议演示
 *
 * 演示流程：初始化注册表与质押池 → 创建 Agent NFT → 注册 Agent → 创建声誉 → 添加评分
 *
 * 使用方式：
 *   1. 将 trustless-agents 合约部署到 devnet，并执行一次 init_registry、init_stake_pool
 *   2. 复制 .env.example 为 .env，填入 PACKAGE_ID、REGISTRY_ID、STAKE_POOL_ID、DEMO_PRIVATE_KEY
 *   3. npm install && npm run demo
 */

import "dotenv/config";
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";

const NETWORK = process.env.NETWORK ?? "devnet";
const PACKAGE_ID = process.env.PACKAGE_ID ?? "0x94a476f4b925efb03bb04f0e8e88ba9a8533ec197f6d20cd510995ad2d3a07d8";
const REGISTRY_ID = process.env.REGISTRY_ID;
const STAKE_POOL_ID = process.env.STAKE_POOL_ID;
const DRY_RUN = process.env.DRY_RUN === "1";

function log(msg: string, data?: unknown) {
  console.log(`[EIP-8004 Demo] ${msg}`, data !== undefined ? data : "");
}

function getKeypair(): Ed25519Keypair {
  const raw = process.env.DEMO_PRIVATE_KEY;
  if (!raw) {
    log("DEMO_PRIVATE_KEY 未设置，使用随机 keypair（仅用于演示）");
    return new Ed25519Keypair();
  }
  const { schema, secretKey } = decodeSuiPrivateKey(raw);
  if (schema !== "ED25519") throw new Error("仅支持 ED25519");
  return Ed25519Keypair.fromSecretKey(secretKey);
}

async function main() {
  const client = new SuiClient({ url: getFullnodeUrl(NETWORK as "devnet" | "testnet" | "mainnet") });
  const keypair = getKeypair();
  const sender = keypair.getPublicKey().toSuiAddress();
  log(`网络: ${NETWORK}, 发送方: ${sender}`);
  log(`合约 Package: ${PACKAGE_ID}`);
  if (!DRY_RUN && !process.env.DEMO_PRIVATE_KEY) {
    log("提示: 未设置 DEMO_PRIVATE_KEY 时使用随机地址，需先在 devnet 水龙头领取 SUI: sui client faucet（用该地址）或导出已有地址私钥填入 .env");
  }

  let registryId = REGISTRY_ID;
  let stakePoolId = STAKE_POOL_ID;

  // ---------- 1. 初始化注册表（若尚未初始化） ----------
  if (!registryId) {
    log("步骤 1: 初始化全局注册表 (init_registry)");
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::agent_registry::init_registry`,
      arguments: [],
    });
    if (DRY_RUN) {
      log("(DRY_RUN) 跳过执行 init_registry");
    } else {
      const res = await client.signAndExecuteTransaction({
        signer: keypair,
        transaction: tx,
        options: { showEffects: true, showObjectChanges: true },
      });
      if (res.effects?.status?.status !== "success") throw new Error("init_registry 失败: " + JSON.stringify(res.effects));
      const created = (res as { objectChanges?: { type: string; objectId: string }[] }).objectChanges?.find(
        (c) => c.type === "published" || (String(c).includes("Registry") && "objectId" in c)
      );
      const createdIds = res.effects?.created;
      if (createdIds?.length) registryId = createdIds[0].reference.objectId;
      log("Registry 已创建:", registryId);
    }
  } else {
    log("使用已有 Registry:", registryId);
  }

  // ---------- 2. 初始化质押池（若尚未初始化） ----------
  if (!stakePoolId) {
    log("步骤 2: 初始化质押池 (init_stake_pool)");
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::validation_system::init_stake_pool`,
      arguments: [],
    });
    if (DRY_RUN) {
      log("(DRY_RUN) 跳过执行 init_stake_pool");
    } else {
      const res = await client.signAndExecuteTransaction({
        signer: keypair,
        transaction: tx,
        options: { showEffects: true, showObjectChanges: true },
      });
      if (res.effects?.status?.status !== "success") throw new Error("init_stake_pool 失败");
      const createdIds = res.effects?.created;
      if (createdIds?.length) stakePoolId = createdIds[0].reference.objectId;
      log("StakePool 已创建:", stakePoolId);
    }
  } else {
    log("使用已有 StakePool:", stakePoolId);
  }

  // ---------- 3. 创建 Agent NFT ----------
  log("步骤 3: 创建 Agent NFT (create_agent)");
  const agentId = 1;
  const name = "EIP-8004 Demo Agent";
  const description = "Trustless Agents 协议演示用 Agent";
  const imageUrl = "https://raw.githubusercontent.com/sui-typescript/sui/main/apps/icons/sui-icon.svg";

  const tx3 = new Transaction();
  tx3.moveCall({
    target: `${PACKAGE_ID}::agent_nft::create_agent`,
    arguments: [
      tx3.pure.u64(agentId),
      tx3.pure.string(name),
      tx3.pure.string(description),
      tx3.pure.string(imageUrl),
    ],
  });

  let agentNftId: string | null = null;
  if (!DRY_RUN) {
    const res3 = await client.signAndExecuteTransaction({
      signer: keypair,
      transaction: tx3,
      options: { showEffects: true, showObjectChanges: true },
    });
    if (res3.effects?.status?.status !== "success") throw new Error("create_agent 失败");
    const created = res3.effects?.created;
    if (created?.length) agentNftId = created[0].reference.objectId;
    log("Agent NFT 已创建:", agentNftId);
  } else {
    log("(DRY_RUN) 跳过 create_agent");
  }

  // ---------- 4. 注册 Agent（需 PTB + 复杂参数，此处用占位；完整实现见 DEPLOYMENT.md） ----------
  if (agentNftId && registryId && !DRY_RUN) {
    log("步骤 4: 注册 Agent (register_agent) — 使用 PTB 占位，实际需 BCS 序列化 capabilities/endpoints/trust_model");
    log("  请使用 CLI 或完整 BCS 脚本调用 register_agent，或参考 DEPLOYMENT.md 中的 TypeScript 示例");
    // 可选：在此处用 bcs 序列化后调用 register_agent
  }

  // ---------- 5. 创建声誉对象（需要 AgentRegistration ID；若未执行 register_agent 则用 agent_nft 地址模拟） ----------
  const registrationIdForRep = agentNftId ?? sender;
  log("步骤 5: 创建 Agent 声誉 (create_agent_reputation)");
  let reputationId: string | null = null;
  if (DRY_RUN) {
    log("(DRY_RUN) 跳过 create_agent_reputation");
  } else {
    const tx5 = new Transaction();
    tx5.moveCall({
      target: `${PACKAGE_ID}::reputation_system::create_agent_reputation`,
      arguments: [tx5.pure.address(registrationIdForRep), tx5.pure.address(sender)],
    });
    const res5 = await client.signAndExecuteTransaction({
      signer: keypair,
      transaction: tx5,
      options: { showEffects: true },
    });
    if (res5.effects?.status?.status !== "success") throw new Error("create_agent_reputation 失败");
    const created = res5.effects?.created;
    if (created?.length) reputationId = created[0].reference.objectId;
    log("AgentReputation 已创建:", reputationId);
  }

  // ---------- 6. 添加评分 ----------
  if (reputationId) {
    log("步骤 6: 添加评分 (add_rating)");
    const tx6 = new Transaction();
    tx6.moveCall({
      target: `${PACKAGE_ID}::reputation_system::add_rating`,
      arguments: [
        tx6.object(reputationId),
        tx6.pure.u8(8),
        tx6.pure.option("string", null),
        tx6.pure.string("performance"),
      ],
    });
    const res6 = await client.signAndExecuteTransaction({
      signer: keypair,
      transaction: tx6,
      options: { showEffects: true },
    });
    if (res6.effects?.status?.status !== "success") throw new Error("add_rating 失败");
    log("评分已添加 (8 分, performance)");
  }

  log("---");
  log("EIP-8004 演示流程结束。");
  log("可选后续：调用 register_agent 注册能力与端点、调用 validation_system 进行质押/zkML/TEE 验证。");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
