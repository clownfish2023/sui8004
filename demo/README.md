# EIP-8004 Trustless Agents 演示

本目录包含一个**简单演示脚本**，用于在 Sui Devnet 上演示 [EIP-8004 Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004) 协议的核心流程。

## 协议要点（EIP-8004）

- **代理注册与发现**：在链上注册 Agent 的元数据、能力与通信端点
- **信任模型**：声誉、质押/zkML 验证、TEE 证明
- **Agent NFT**：用 NFT 表示代理所有权（Sui 上为对象模型）
- **声誉系统**：链上评分与聚合

## 演示流程

脚本会按顺序执行（若未提供已有对象 ID 则自动创建）：

| 步骤 | 说明 |
|------|------|
| 1 | **init_registry** — 初始化全局注册表（共享对象） |
| 2 | **init_stake_pool** — 初始化质押池（共享对象） |
| 3 | **create_agent** — 创建 Agent NFT（名称、描述、图片） |
| 4 | **register_agent** — 注册 Agent（能力、端点、信任模型）— 当前为占位，完整需 BCS 序列化 |
| 5 | **create_agent_reputation** — 为 Agent 创建声誉对象 |
| 6 | **add_rating** — 添加一条评分（1–10 分 + 分类） |

## 前置条件

1. **合约已部署到 Devnet**  
   在项目根目录执行：
   ```bash
   sui client switch --env devnet
   sui client faucet
   cd trustless-agents
   sui client test-publish --gas-budget 100000000 --build-env testnet --pubfile-path Pub.devnet.toml
   ```
   记下 `Pub.devnet.toml` 中的 `published-at`（即 `PACKAGE_ID`）。

2. **Node.js 18+**  
   已安装 `node` 与 `npm`。

## 使用方式

```bash
cd demo
cp .env.example .env
# 编辑 .env：至少设置 PACKAGE_ID；若已 init 过可填 REGISTRY_ID、STAKE_POOL_ID；可选 DEMO_PRIVATE_KEY
npm install
npm run demo
```

- **不填 `DEMO_PRIVATE_KEY`**：脚本会使用随机 keypair；该地址在 devnet 上无 SUI，会报错 "No valid gas coins"。请使用已领取过水龙头的地址私钥（如 `sui keytool export --key-identity <addr>` 后填入），或先 `sui client faucet` 再导出当前 active 地址私钥填入 `.env`。
- **只检查不执行**：`DRY_RUN=1 npm run demo`（不会发交易，无需 gas）。

## 环境变量说明

| 变量 | 说明 |
|------|------|
| `NETWORK` | 网络：`devnet` / `testnet` / `mainnet`，默认 `devnet` |
| `PACKAGE_ID` | 已部署的 trustless_agents 合约 Package ID |
| `REGISTRY_ID` | 已有 Registry 对象 ID（可选，不填则执行 init_registry） |
| `STAKE_POOL_ID` | 已有 StakePool 对象 ID（可选，不填则执行 init_stake_pool） |
| `DEMO_PRIVATE_KEY` | 演示用私钥（可选，不填则随机生成） |
| `DRY_RUN` | 设为 `1` 时只构建交易不发送 |

## 完整 register_agent 与 CLI 示例

`register_agent` 需要传入能力列表、端点列表和信任模型等复杂参数，当前脚本中为占位。完整调用可参考：

- 仓库内 **DEPLOYMENT.md** 的 TypeScript/BCS 示例
- 或使用 Sui CLI 分步调用（需先准备好 capabilities/endpoints 的编码）

例如创建 Agent NFT 后，用 CLI 注册（需将 `<PACKAGE_ID>`、`<REGISTRY_ID>`、`<AGENT_NFT_ID>` 等替换为实际值）：

```bash
# 创建 Agent NFT 后得到 AGENT_NFT_ID，再使用 SDK 或 CLI 调用 register_agent
sui client call --package <PACKAGE_ID> --module agent_registry --function register_agent \
  --args <REGISTRY_ID> <AGENT_NFT_ID> ... # 其余参数需按 BCS 构造
```

## 相关链接

- [EIP-8004: Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004)
- [Sui TypeScript SDK](https://sdk.mystenlabs.com/sui)
- 项目根目录 **README.md**、**DEPLOYMENT.md**
