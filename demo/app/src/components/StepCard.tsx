import { useState } from "react";
import "./StepCard.css";

type Step = {
  id: string;
  title: string;
  description: string;
  action: string | null;
  placeholder?: boolean;
  hasForm?: boolean;
  needsAgentId?: boolean;
  needsReputationId?: boolean;
};

type StepCardProps = {
  step: Step;
  disabled: boolean;
  onExecute: (stepId: string, form?: Record<string, string | number>) => void;
};

export function StepCard({ step, disabled, onExecute }: StepCardProps) {
  const [agentId, setAgentId] = useState("");
  const [name, setName] = useState("EIP-8004 Demo Agent");
  const [description, setDescription] = useState("Trustless Agents demo");
  const [imageUrl, setImageUrl] = useState("https://raw.githubusercontent.com/sui-typescript/sui/main/apps/icons/sui-icon.svg");
  const [reputationId, setReputationId] = useState("");
  const [score, setScore] = useState(8);
  const [category, setCategory] = useState("performance");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (step.placeholder || !step.action) return;
    const form: Record<string, string | number> = {};
    if (step.hasForm) {
      form.agentId = "1";
      form.name = name;
      form.description = description;
      form.imageUrl = imageUrl;
    }
    if (step.needsAgentId) form.agentId = agentId;
    if (step.needsReputationId) {
      form.reputationId = reputationId;
      form.score = score;
      form.category = category;
    }
    onExecute(step.id, form);
  };

  if (step.placeholder) {
    return (
      <li className="step-card step-card--placeholder">
        <h3>{step.title}</h3>
        <p>{step.description}</p>
        <p className="step-note">
          Use the CLI or a script with BCS-encoded args. See <code>DEPLOYMENT.md</code>.
        </p>
      </li>
    );
  }

  return (
    <li className="step-card">
      <h3>{step.title}</h3>
      <p>{step.description}</p>
      <form onSubmit={handleSubmit} className="step-form">
        {step.hasForm && (
          <>
            <label>
              Name
              <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Agent name" />
            </label>
            <label>
              Description
              <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Description" />
            </label>
            <label>
              Image URL
              <input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://..." />
            </label>
          </>
        )}
        {step.needsAgentId && (
          <label>
            Agent / Registration ID (address)
            <input
              value={agentId}
              onChange={(e) => setAgentId(e.target.value)}
              placeholder="0x..."
              required
            />
          </label>
        )}
        {step.needsReputationId && (
          <>
            <label>
              Reputation Object ID
              <input
                value={reputationId}
                onChange={(e) => setReputationId(e.target.value)}
                placeholder="0x..."
                required
              />
            </label>
            <label>
              Score (1–10)
              <input
                type="number"
                min={1}
                max={10}
                value={score}
                onChange={(e) => setScore(Number(e.target.value))}
              />
            </label>
            <label>
              Category
              <select value={category} onChange={(e) => setCategory(e.target.value)}>
                <option value="performance">performance</option>
                <option value="reliability">reliability</option>
                <option value="security">security</option>
                <option value="user_experience">user_experience</option>
              </select>
            </label>
          </>
        )}
        <button type="submit" disabled={disabled}>
          {step.action}
        </button>
      </form>
    </li>
  );
}
