import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { CONTRACT, NETWORK } from "../lib/contract";
import { StepCard } from "./StepCard";
import "./StepsPanel.css";

const CHAIN = `sui:${NETWORK}` as const;

const STEPS = [
  {
    id: "init_registry",
    title: "1. Init Registry",
    description: "Create the global agent registry (shared object). Run once per network.",
    action: "Init Registry",
  },
  {
    id: "init_stake_pool",
    title: "2. Init Stake Pool",
    description: "Create the stake pool for validation. Run once per network.",
    action: "Init Stake Pool",
  },
  {
    id: "create_agent",
    title: "3. Create Agent NFT",
    description: "Mint an Agent NFT with name, description, and image URL.",
    action: "Create Agent",
    hasForm: true,
  },
  {
    id: "register_agent",
    title: "4. Register Agent",
    description: "Register capabilities & endpoints (requires BCS encoding). See DEPLOYMENT.md for full flow.",
    action: null,
    placeholder: true,
  },
  {
    id: "create_reputation",
    title: "5. Create Agent Reputation",
    description: "Create a reputation object for an agent (use Agent NFT ID if not registered yet).",
    action: "Create Reputation",
    needsAgentId: true,
  },
  {
    id: "add_rating",
    title: "6. Add Rating",
    description: "Add a 1–10 rating for a category (e.g. performance, reliability).",
    action: "Add Rating",
    needsReputationId: true,
  },
] as const;

export function StepsPanel() {
  const account = useCurrentAccount();
  const { mutate: signAndExecute, isPending, data, reset } = useSignAndExecuteTransaction();

  const buildTx = (stepId: string, form?: { agentId?: string; name?: string; description?: string; imageUrl?: string; reputationId?: string; score?: number; category?: string }) => {
    const tx = new Transaction();

    switch (stepId) {
      case "init_registry":
        tx.moveCall({
          target: `${CONTRACT.agentRegistry}::init_registry`,
          arguments: [],
        });
        break;
      case "init_stake_pool":
        tx.moveCall({
          target: `${CONTRACT.validationSystem}::init_stake_pool`,
          arguments: [],
        });
        break;
      case "create_agent": {
        const agentId = Number(form?.agentId ?? "1");
        const name = form?.name ?? "EIP-8004 Demo Agent";
        const description = form?.description ?? "Trustless Agents demo";
        const imageUrl = form?.imageUrl ?? "https://raw.githubusercontent.com/sui-typescript/sui/main/apps/icons/sui-icon.svg";
        tx.moveCall({
          target: `${CONTRACT.agentNft}::create_agent`,
          arguments: [
            tx.pure.u64(agentId),
            tx.pure.string(name),
            tx.pure.string(description),
            tx.pure.string(imageUrl),
          ],
        });
        break;
      }
      case "create_reputation": {
        const registrationId = form?.agentId ?? "";
        if (!registrationId) return null;
        tx.moveCall({
          target: `${CONTRACT.reputationSystem}::create_agent_reputation`,
          arguments: [
            tx.pure.address(registrationId),
            tx.pure.address(account!.address),
          ],
        });
        break;
      }
      case "add_rating": {
        const repId = form?.reputationId ?? "";
        const score = Math.min(10, Math.max(1, Number(form?.score ?? "8")));
        const category = form?.category ?? "performance";
        if (!repId) return null;
        tx.moveCall({
          target: `${CONTRACT.reputationSystem}::add_rating`,
          arguments: [
            tx.object(repId),
            tx.pure.u8(score),
            tx.pure.option("string", null),
            tx.pure.string(category),
          ],
        });
        break;
      }
      default:
        return null;
    }

    return tx;
  };

  const handleExecute = (
    stepId: string,
    form?: { agentId?: string; name?: string; description?: string; imageUrl?: string; reputationId?: string; score?: number; category?: string }
  ) => {
    const transaction = buildTx(stepId, form);
    if (!transaction) return;
    reset();
    signAndExecute(
      {
        transaction: transaction as never,
        chain: CHAIN,
      },
      {
        onSuccess: (result) => {
          console.log("Transaction success", result);
        },
      }
    );
  };

  const digest = data && typeof data === "object" && "digest" in data ? (data as { digest: string }).digest : null;

  return (
    <div className="steps-panel">
      {!account ? (
        <p className="connect-hint">Connect a wallet to run EIP-8004 steps.</p>
      ) : (
        <>
          {isPending && (
            <p className="pending-hint">Confirm the transaction in your wallet…</p>
          )}
          {digest && (
            <p className="result-hint">
              Last tx: <code>{digest}</code> — check explorer for created objects.
            </p>
          )}
          <ul className="step-list">
            {STEPS.map((step) => (
              <StepCard
                key={step.id}
                step={step}
                disabled={!account || isPending}
                onExecute={handleExecute}
              />
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
