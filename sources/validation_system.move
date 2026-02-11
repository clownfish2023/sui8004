module trustless_agents::validation_system {
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::transfer;

    /// Staking information
    public struct StakeInfo has copy, drop, store {
        /// Staker address
        staker: address,
        /// Staked amount
        amount: u64,
        /// Staking timestamp
        staked_at: u64,
        /// Expiration time (0 means never expires)
        expires_at: u64,
    }

    /// zkML verification information
    public struct ZkmlProof has copy, drop, store {
        /// Proof hash
        proof_hash: String,
        /// Circuit ID
        circuit_id: String,
        /// Public input hash
        public_input_hash: String,
        /// Verification timestamp
        verified_at: u64,
        /// Verifier address
        verifier: address,
    }

    /// TEE attestation information
    public struct TeeAttestation has copy, drop, store {
        /// TEE report hash
        report_hash: String,
        /// TEE provider: "intel_sgx", "amd_sev", "aws_nitro", etc.
        provider: String,
        /// Verification timestamp
        verified_at: u64,
        /// Verifier address
        verifier: address,
    }

    /// Agent validation data
    public struct AgentValidation has key {
        id: UID,
        /// Associated Agent registration ID
        agent_registration_id: address,
        /// Agent owner
        agent_owner: address,
        /// Staking information
        stake_info: Option<StakeInfo>,
        /// zkML proof list
        zkml_proofs: vector<ZkmlProof>,
        /// TEE attestation list
        tee_attestations: vector<TeeAttestation>,
        /// Validation status
        is_validated: bool,
        /// Validation types
        validation_types: vector<String>,
        /// Version number
        version: u64,
    }

    /// Staking pool (shared object, stores staked SUI)
    public struct StakePool has key {
        id: UID,
        /// Total staked amount
        total_staked: u64,
        /// Staked balance
        balance: Balance<SUI>,
    }

    /// Staking event
    public struct Staked has copy, drop {
        agent_id: address,
        staker: address,
        amount: u64,
        expires_at: u64,
    }

    /// Unstaking event
    public struct Unstaked has copy, drop {
        agent_id: address,
        staker: address,
        amount: u64,
    }

    /// zkML proof added event
    public struct ZkmlProofAdded has copy, drop {
        agent_id: address,
        proof_hash: String,
        circuit_id: String,
        verifier: address,
    }

    /// TEE attestation added event
    public struct TeeAttestationAdded has copy, drop {
        agent_id: address,
        report_hash: String,
        provider: String,
        verifier: address,
    }

    /// Initialize staking pool
    public entry fun init_stake_pool(ctx: &mut TxContext) {
        let pool = StakePool {
            id: object::new(ctx),
            total_staked: 0,
            balance: balance::zero(),
        };
        transfer::share_object(pool);
    }

    /// Create agent validation data
    public entry fun create_agent_validation(
        agent_registration_id: address,
        agent_owner: address,
        ctx: &mut TxContext
    ) {
        let validation = AgentValidation {
            id: object::new(ctx),
            agent_registration_id,
            agent_owner,
            stake_info: option::none(),
            zkml_proofs: vector::empty<ZkmlProof>(),
            tee_attestations: vector::empty<TeeAttestation>(),
            is_validated: false,
            validation_types: vector::empty<String>(),
            version: 1,
        };
        transfer::share_object(validation);
    }

    /// Add stake
    public entry fun add_stake(
        pool: &mut StakePool,
        validation: &mut AgentValidation,
        coin: Coin<SUI>,
        expires_at: u64,
        ctx: &TxContext
    ) {
        // Only agent owner can stake
        assert!(validation.agent_owner == tx_context::sender(ctx), 0);

        let amount = coin::value(&coin);

        // Deposit coins into staking pool
        let coin_balance = coin::into_balance(coin);
        balance::join(&mut pool.balance, coin_balance);

        pool.total_staked = pool.total_staked + amount;

        // Update validation data
        let stake_info = StakeInfo {
            staker: tx_context::sender(ctx),
            amount,
            staked_at: tx_context::epoch(ctx),
            expires_at,
        };

        validation.stake_info = option::some(stake_info);
        validation.is_validated = true;

        // Add validation type
        if (!contains(&validation.validation_types, utf8(b"stake"))) {
            vector::push_back(&mut validation.validation_types, utf8(b"stake"));
        };

        validation.version = validation.version + 1;

        // Emit staking event
        event::emit(Staked {
            agent_id: validation.agent_registration_id,
            staker: tx_context::sender(ctx),
            amount,
            expires_at,
        });
    }

    /// Unstake
    public entry fun unstake(
        pool: &mut StakePool,
        validation: &mut AgentValidation,
        amount: u64,
        ctx: &mut TxContext
    ) {
        // Only agent owner can unstake
        assert!(validation.agent_owner == tx_context::sender(ctx), 0);

        // Check if there is a stake
        assert!(option::is_some(&validation.stake_info), 1);

        let stake_info = option::borrow(&validation.stake_info);

        // Validate unstake amount
        assert!(amount <= stake_info.amount, 2);

        // Check if stake has expired
        if (stake_info.expires_at > 0) {
            assert!(tx_context::epoch(ctx) >= stake_info.expires_at, 3);
        };

        // Withdraw from staking pool
        let withdrawn = balance::split(&mut pool.balance, amount);
        let coin = coin::from_balance(withdrawn, ctx);

        // Update staking information
        let remaining = stake_info.amount - amount;
        if (remaining == 0) {
            // Fully unstaked
            let _ = option::extract(&mut validation.stake_info);
            validation.is_validated = (
                vector::length(&validation.zkml_proofs) > 0 ||
                vector::length(&validation.tee_attestations) > 0
            );
            remove_validation_type(&mut validation.validation_types, utf8(b"stake"));
        } else {
            // Partial unstake
            option::fill(&mut validation.stake_info, StakeInfo {
                staker: stake_info.staker,
                amount: remaining,
                staked_at: stake_info.staked_at,
                expires_at: stake_info.expires_at,
            });
        };

        pool.total_staked = pool.total_staked - amount;
        validation.version = validation.version + 1;

        // Return to user
        transfer::public_transfer(coin, tx_context::sender(ctx));

        // Emit unstaking event
        event::emit(Unstaked {
            agent_id: validation.agent_registration_id,
            staker: tx_context::sender(ctx),
            amount,
        });
    }

    /// Add zkML proof
    public entry fun add_zkml_proof(
        validation: &mut AgentValidation,
        proof_hash: String,
        circuit_id: String,
        public_input_hash: String,
        ctx: &TxContext
    ) {
        // Only agent owner can add proof
        assert!(validation.agent_owner == tx_context::sender(ctx), 0);

        let proof = ZkmlProof {
            proof_hash,
            circuit_id,
            public_input_hash,
            verified_at: tx_context::epoch(ctx),
            verifier: tx_context::sender(ctx),
        };

        vector::push_back(&mut validation.zkml_proofs, proof);
        validation.is_validated = true;

        // Add validation type
        if (!contains(&validation.validation_types, utf8(b"zkml"))) {
            vector::push_back(&mut validation.validation_types, utf8(b"zkml"));
        };

        validation.version = validation.version + 1;

        // Emit event
        event::emit(ZkmlProofAdded {
            agent_id: validation.agent_registration_id,
            proof_hash,
            circuit_id,
            verifier: tx_context::sender(ctx),
        });
    }

    /// Add TEE attestation
    public entry fun add_tee_attestation(
        validation: &mut AgentValidation,
        report_hash: String,
        provider: String,
        ctx: &TxContext
    ) {
        // Only agent owner can add attestation
        assert!(validation.agent_owner == tx_context::sender(ctx), 0);

        let attestation = TeeAttestation {
            report_hash,
            provider,
            verified_at: tx_context::epoch(ctx),
            verifier: tx_context::sender(ctx),
        };

        vector::push_back(&mut validation.tee_attestations, attestation);
        validation.is_validated = true;

        // Add validation type
        if (!contains(&validation.validation_types, utf8(b"tee"))) {
            vector::push_back(&mut validation.validation_types, utf8(b"tee"));
        };

        validation.version = validation.version + 1;

        // Emit event
        event::emit(TeeAttestationAdded {
            agent_id: validation.agent_registration_id,
            report_hash,
            provider,
            verifier: tx_context::sender(ctx),
        });
    }

    /// Get validation information
    public fun get_validation_info(
        validation: &AgentValidation
    ): (address, address, Option<StakeInfo>, u64, u64, u64, vector<String>) {
        (
            validation.agent_registration_id,
            validation.agent_owner,
            validation.stake_info,
            vector::length(&validation.zkml_proofs),
            vector::length(&validation.tee_attestations),
            validation.version,
            validation.validation_types,
        )
    }

    /// Get staking information
    public fun get_stake_info(validation: &AgentValidation): Option<StakeInfo> {
        validation.stake_info
    }

    /// Get zkML proof list
    public fun get_zkml_proofs(validation: &AgentValidation): vector<ZkmlProof> {
        validation.zkml_proofs
    }

    /// Get TEE attestation list
    public fun get_tee_attestations(validation: &AgentValidation): vector<TeeAttestation> {
        validation.tee_attestations
    }

    /// Get staking pool statistics
    public fun get_stake_pool_stats(pool: &StakePool): (u64, u64) {
        (pool.total_staked, balance::value(&pool.balance))
    }

    /// Check if a specific validation type is supported
    public fun has_validation_type(validation: &AgentValidation, validation_type: String): bool {
        contains(&validation.validation_types, validation_type)
    }

    /// Get all validation types
    public fun get_validation_types(validation: &AgentValidation): vector<String> {
        validation.validation_types
    }

    /// Check if validated
    public fun is_validated(validation: &AgentValidation): bool {
        validation.is_validated
    }

    /// Helper function: check if string exists in vector
    fun contains(vec: &vector<String>, item: String): bool {
        let mut i = 0;
        let len = vector::length(vec);
        while (i < len) {
            if (*vector::borrow(vec, i) == item) {
                return true
            };
            i = i + 1;
        };
        false
    }

    /// Helper function: remove string from vector (find index first to avoid borrow conflict)
    fun remove_validation_type(vec: &mut vector<String>, item: String) {
        let mut i = 0;
        let len = vector::length(vec);
        let mut found = false;
        while (i < len) {
            if (*vector::borrow(vec, i) == item) {
                found = true;
                break
            };
            i = i + 1;
        };
        if (found) {
            let _ = vector::remove(vec, i);
        }
    }
}