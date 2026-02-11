module trustless_agents::agent_registry {
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::event;
    use sui::dynamic_field;

    /// Agent capability
    public struct Capability has copy, drop, store {
        name: String,
        description: String,
        /// Capability type: "text", "image", "audio", "video", "code", "data_analysis", etc.
        capability_type: String,
        /// Capability version
        version: String,
    }

    /// Communication endpoint
    public struct Endpoint has copy, drop, store {
        /// Protocol type: "mcp", "a2a", "http", "websocket", etc.
        protocol: String,
        /// Endpoint URL
        url: String,
        /// Endpoint description
        description: String,
        /// Whether validation is supported
        supports_validation: bool,
        /// Validation type: "stake", "zkml", "tee"
        validation_type: Option<String>,
    }

    /// Trust model configuration
    public struct TrustModel has copy, drop, store {
        /// Whether reputation system is supported
        supports_reputation: bool,
        /// Whether stake validation is supported
        supports_stake_validation: bool,
        /// Whether zkML validation is supported
        supports_zkml_validation: bool,
        /// Whether TEE attestation is supported
        supports_tee_attestation: bool,
        /// Minimum stake amount (if supported)
        min_stake_amount: Option<u64>,
    }

    /// Agent registration information
    public struct AgentRegistration has key {
        id: UID,
        /// Associated Agent NFT object ID
        agent_nft_id: address,
        /// Agent capabilities list
        capabilities: vector<Capability>,
        /// Communication endpoints list
        endpoints: vector<Endpoint>,
        /// ENS name (optional)
        ens_name: Option<String>,
        /// Wallet address
        wallet_address: address,
        /// Trust model configuration
        trust_model: TrustModel,
        /// Metadata hash (stored on IPFS or other decentralized storage)
        metadata_hash: String,
        /// Version number
        version: u64,
    }

    /// Global registry (singleton)
    public struct Registry has key {
        id: UID,
        /// Next available agent_id
        next_agent_id: u64,
        /// Total number of registered agents
        total_agents: u64,
    }

    /// Registration event
    public struct AgentRegistered has copy, drop {
        agent_id: address,
        agent_nft_id: address,
        owner: address,
        capabilities_count: u64,
        endpoints_count: u64,
    }

    /// Registration update event
    public struct RegistrationUpdated has copy, drop {
        agent_id: address,
        updater: address,
        version: u64,
    }

    /// Initialize global registry
    public entry fun init_registry(ctx: &mut TxContext) {
        let registry = Registry {
            id: object::new(ctx),
            next_agent_id: 1,
            total_agents: 0,
        };
        transfer::share_object(registry);
    }

    /// Register agent
    public entry fun register_agent(
        registry: &mut Registry,
        agent_nft_id: address,
        capabilities: vector<Capability>,
        endpoints: vector<Endpoint>,
        ens_name: Option<String>,
        trust_model: TrustModel,
        metadata_hash: String,
        ctx: &mut TxContext
    ) {
        let registration = AgentRegistration {
            id: object::new(ctx),
            agent_nft_id,
            capabilities,
            endpoints,
            ens_name,
            wallet_address: tx_context::sender(ctx),
            trust_model,
            metadata_hash,
            version: 1,
        };

        let reg_id = object::id_address(&registration);

        // Emit registration event
        event::emit(AgentRegistered {
            agent_id: reg_id,
            agent_nft_id,
            owner: tx_context::sender(ctx),
            capabilities_count: vector::length(&registration.capabilities),
            endpoints_count: vector::length(&registration.endpoints),
        });

        // Update registry statistics
        registry.total_agents = registry.total_agents + 1;
        registry.next_agent_id = registry.next_agent_id + 1;

        // Share registration object
        transfer::share_object(registration);
    }

    /// Update agent registration information
    public entry fun update_registration(
        registry: &mut AgentRegistration,
        capabilities: Option<vector<Capability>>,
        endpoints: Option<vector<Endpoint>>,
        ens_name: Option<String>,
        trust_model: Option<TrustModel>,
        metadata_hash: Option<String>,
        ctx: &TxContext
    ) {
        // Only owner can update
        assert!(registry.wallet_address == tx_context::sender(ctx), 0);

        if (option::is_some(&capabilities)) {
            registry.capabilities = option::destroy_some(capabilities);
        } else {
            option::destroy_none(capabilities);
        };

        if (option::is_some(&endpoints)) {
            registration.endpoints = option::destroy_some(endpoints);
        } else {
            option::destroy_none(endpoints);
        };

        if (option::is_some(&ens_name)) {
            registry.ens_name = option::destroy_some(ens_name);
        } else {
            option::destroy_none(ens_name);
        };

        if (option::is_some(&trust_model)) {
            registry.trust_model = option::destroy_some(trust_model);
        } else {
            option::destroy_none(trust_model);
        };

        if (option::is_some(&metadata_hash)) {
            registry.metadata_hash = option::destroy_some(metadata_hash);
        } else {
            option::destroy_none(metadata_hash);
        };

        registry.version = registry.version + 1;

        // Emit update event
        event::emit(RegistrationUpdated {
            agent_id: object::id_address(registry),
            updater: tx_context::sender(ctx),
            version: registry.version,
        });
    }

    /// Get registration information
    public fun get_registration_info(
        registry: &AgentRegistration
    ): (address, vector<Capability>, vector<Endpoint>, Option<String>, address, TrustModel, String, u64) {
        (
            registry.agent_nft_id,
            registry.capabilities,
            registry.endpoints,
            registry.ens_name,
            registry.wallet_address,
            registry.trust_model,
            registry.metadata_hash,
            registry.version,
        )
    }

    /// Get registry statistics
    public fun get_registry_stats(registry: &Registry): (u64, u64) {
        (registry.next_agent_id, registry.total_agents)
    }

    /// Check if agent supports a specific capability
    public fun has_capability(registry: &AgentRegistration, capability_name: String): bool {
        let i = 0;
        let len = vector::length(&registry.capabilities);
        while (i < len) {
            let cap = vector::borrow(&registry.capabilities, i);
            if (cap.name == capability_name) {
                return true
            };
            i = i + 1;
        };
        false
    }

    /// Get all capability names
    public fun get_capability_names(registry: &AgentRegistration): vector<String> {
        let i = 0;
        let len = vector::length(&registry.capabilities);
        let names = vector::empty<String>();
        while (i < len) {
            let cap = vector::borrow(&registry.capabilities, i);
            vector::push_back(&mut names, cap.name);
            i = i + 1;
        };
        names
    }

    /// Get all endpoint URLs
    public fun get_endpoint_urls(registry: &AgentRegistration): vector<String> {
        let i = 0;
        let len = vector::length(&registry.endpoints);
        let urls = vector::empty<String>();
        while (i < len) {
            let endpoint = vector::borrow(&registry.endpoints, i);
            vector::push_back(&mut urls, endpoint.url);
            i = i + 1;
        };
        urls
    }

    /// Get endpoints by protocol type
    public fun get_endpoints_by_protocol(registry: &AgentRegistration, protocol: String): vector<Endpoint> {
        let i = 0;
        let len = vector::length(&registry.endpoints);
        let result = vector::empty<Endpoint>();
        while (i < len) {
            let endpoint = vector::borrow(&registry.endpoints, i);
            if (endpoint.protocol == protocol) {
                vector::push_back(&mut result, *endpoint);
            };
            i = i + 1;
        };
        result
    }
}