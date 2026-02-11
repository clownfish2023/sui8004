module trustless_agents::agent_nft {
    use std::string::{String, utf8};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::display::{Self, Display};
    use sui::event;
    use sui::package::Publisher;

    /// Agent NFT - Represents an AI agent
    public struct AgentNFT has key, store {
        id: UID,
        /// Unique identifier for the agent
        agent_id: u64,
        /// Agent name
        name: String,
        /// Agent description
        description: String,
        /// Agent image URL
        image_url: String,
        /// Owner address
        owner: address,
        /// Creation timestamp
        created_at: u64,
        /// Version number
        version: u64,
    }

    /// Agent creation event
    public struct AgentCreated has copy, drop {
        agent_id: u64,
        agent_address: address,
        owner: address,
        name: String,
    }

    /// Agent transfer event
    public struct AgentTransferred has copy, drop {
        agent_id: u64,
        from: address,
        to: address,
    }

    /// Agent update event
    public struct AgentUpdated has copy, drop {
        agent_id: u64,
        updater: address,
        updated_fields: vector<String>,
    }

    /// Create a new Agent NFT
    public entry fun create_agent(
        agent_id: u64,
        name: String,
        description: String,
        image_url: String,
        ctx: &mut TxContext
    ) {
        let agent = AgentNFT {
            id: object::new(ctx),
            agent_id,
            name: name,
            description,
            image_url,
            owner: tx_context::sender(ctx),
            created_at: tx_context::epoch(ctx),
            version: 1,
        };

        let agent_addr = object::id_address(&agent);

        // Emit creation event
        event::emit(AgentCreated {
            agent_id,
            agent_address: agent_addr,
            owner: tx_context::sender(ctx),
            name: name,
        });

        // Transfer to creator
        transfer::public_transfer(agent, tx_context::sender(ctx));
    }

    /// Transfer Agent NFT (object ownership moves to `to`; .owner field is not updated for UID rules)
    public entry fun transfer_agent(
        agent: AgentNFT,
        to: address,
        ctx: &TxContext
    ) {
        let agent_id = agent.agent_id;
        let from = tx_context::sender(ctx);

        event::emit(AgentTransferred {
            agent_id,
            from,
            to,
        });

        transfer::public_transfer(agent, to);
    }

    /// Update agent information
    public entry fun update_agent(
        agent: &mut AgentNFT,
        name: Option<String>,
        description: Option<String>,
        image_url: Option<String>,
        ctx: &TxContext
    ) {
        // Only owner can update
        assert!(agent.owner == tx_context::sender(ctx), 0);

        let mut updated_fields = vector::empty<String>();

        if (option::is_some(&name)) {
            agent.name = option::destroy_some(name);
            vector::push_back(&mut updated_fields, utf8(b"name"));
        } else {
            option::destroy_none(name);
        };

        if (option::is_some(&description)) {
            agent.description = option::destroy_some(description);
            vector::push_back(&mut updated_fields, utf8(b"description"));
        } else {
            option::destroy_none(description);
        };

        if (option::is_some(&image_url)) {
            agent.image_url = option::destroy_some(image_url);
            vector::push_back(&mut updated_fields, utf8(b"image_url"));
        } else {
            option::destroy_none(image_url);
        };

        agent.version = agent.version + 1;

        // Emit update event
        event::emit(AgentUpdated {
            agent_id: agent.agent_id,
            updater: tx_context::sender(ctx),
            updated_fields,
        });
    }

    /// Get agent information
    public fun get_agent_info(agent: &AgentNFT): (u64, String, String, String, address, u64, u64) {
        (
            agent.agent_id,
            agent.name,
            agent.description,
            agent.image_url,
            agent.owner,
            agent.created_at,
            agent.version
        )
    }

    /// Check if address is the owner
    public fun is_owner(agent: &AgentNFT, addr: address): bool {
        agent.owner == addr
    }

    /// Create Display for NFT display (requires &Publisher from package publish)
    public fun create_display(pub: &Publisher, ctx: &mut TxContext): Display<AgentNFT> {
        display::new_with_fields<AgentNFT>(
            pub,
            vector[
                utf8(b"name"),
                utf8(b"description"),
                utf8(b"image_url"),
                utf8(b"link"),
            ],
            vector[
                utf8(b"{name}"),
                utf8(b"{description}"),
                utf8(b"{image_url}"),
                utf8(b"https://trustless-agents.sui/agent/{agent_id}"),
            ],
            ctx
        )
    }
}