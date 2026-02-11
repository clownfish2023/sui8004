import { ConnectButton } from "@mysten/dapp-kit";
import { getPackageId, NETWORK } from "./lib/contract";
import { StepsPanel } from "./components/StepsPanel";
import "./App.css";

function App() {
  const packageId = getPackageId();

  return (
    <div className="app">
      <header className="header">
        <div className="brand">
          <h1>EIP-8004 Trustless Agents</h1>
          <p className="tagline">On-chain agent registry, reputation & validation</p>
        </div>
        <ConnectButton />
      </header>

      <section className="config">
        <span className="config-item">
          <strong>Network:</strong> {NETWORK}
        </span>
        <span className="config-item">
          <strong>Package:</strong>{" "}
          <code className="package-id">{packageId.slice(0, 10)}…{packageId.slice(-8)}</code>
        </span>
      </section>

      <main className="main">
        <StepsPanel />
      </main>

      <footer className="footer">
        <a href="https://eips.ethereum.org/EIPS/eip-8004" target="_blank" rel="noopener noreferrer">
          EIP-8004 Spec
        </a>
        <span>·</span>
        <a href="https://sdk.mystenlabs.com/sui" target="_blank" rel="noopener noreferrer">
          Sui TypeScript SDK
        </a>
      </footer>
    </div>
  );
}

export default App;
