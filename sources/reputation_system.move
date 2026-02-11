module trustless_agents::reputation_system {
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::event;
    use sui::dynamic_field;

    /// Category name + score (Move does not allow vector of tuples in storage)
    public struct CategoryScore has copy, drop, store {
        category_name: String,
        score: u64,
    }

    /// Rating
    public struct Rating has copy, drop, store {
        /// Reviewer address
        reviewer: address,
        /// Score (1-10)
        score: u8,
        /// Review comment
        comment: Option<String>,
        /// Rating timestamp
        timestamp: u64,
        /// Rating category: "performance", "reliability", "security", "user_experience"
        category: String,
    }

    /// Agent reputation data
    public struct AgentReputation has key {
        id: UID,
        /// Associated Agent registration ID
        agent_registration_id: address,
        /// Agent owner
        agent_owner: address,
        /// Total number of ratings
        total_ratings: u64,
        /// Sum of all scores
        total_score: u64,
        /// Average score (precise to 2 decimal places, stored as u64: e.g., 950 represents 9.50)
        average_score: u64,
        /// Average scores for each category
        category_scores: vector<CategoryScore>,
        /// Rating history (stores up to 100 most recent ratings)
        ratings_history: vector<Rating>,
        /// Version number
        version: u64,
    }

    /// Rating added event
    public struct RatingAdded has copy, drop {
        agent_id: address,
        reviewer: address,
        score: u8,
        category: String,
        new_average: u64,
    }

    /// Rating updated event
    public struct RatingUpdated has copy, drop {
        agent_id: address,
        reviewer: address,
        old_score: u8,
        new_score: u8,
        new_average: u64,
    }

    /// Create agent reputation data
    public entry fun create_agent_reputation(
        agent_registration_id: address,
        agent_owner: address,
        ctx: &mut TxContext
    ) {
        let reputation = AgentReputation {
            id: object::new(ctx),
            agent_registration_id,
            agent_owner,
            total_ratings: 0,
            total_score: 0,
            average_score: 0,
            category_scores: vector::empty<CategoryScore>(),
            ratings_history: vector::empty<Rating>(),
            version: 1,
        };
        transfer::share_object(reputation);
    }

    /// Add rating
    public entry fun add_rating(
        reputation: &mut AgentReputation,
        score: u8,
        comment: Option<String>,
        category: String,
        ctx: &TxContext
    ) {
        // Validate score range (1-10)
        assert!(score >= 1 && score <= 10, 1);

        let reviewer = tx_context::sender(ctx);
        let rating = Rating {
            reviewer,
            score,
            comment,
            timestamp: tx_context::epoch(ctx),
            category: category,
        };

        // Update statistics
        reputation.total_ratings = reputation.total_ratings + 1;
        reputation.total_score = reputation.total_score + (score as u64);

        // Calculate new average score (keep 2 decimal places)
        let new_average = (reputation.total_score * 100) / reputation.total_ratings;
        reputation.average_score = new_average;

        // Update category score
        update_category_score(&mut reputation.category_scores, category, score);

        // Add to history (keep up to 100 records)
        if (vector::length(&reputation.ratings_history) >= 100) {
            // Remove oldest record
            let _ = vector::remove(&mut reputation.ratings_history, 0);
        };
        vector::push_back(&mut reputation.ratings_history, rating);

        reputation.version = reputation.version + 1;

        // Emit rating event
        event::emit(RatingAdded {
            agent_id: reputation.agent_registration_id,
            reviewer,
            score,
            category,
            new_average,
        });
    }

    /// Update existing rating
    public entry fun update_rating(
        reputation: &mut AgentReputation,
        old_score: u8,
        new_score: u8,
        new_comment: Option<String>,
        ctx: &TxContext
    ) {
        // Validate new score range
        assert!(new_score >= 1 && new_score <= 10, 1);

        let reviewer = tx_context::sender(ctx);
        let mut found = false;
        let mut i = 0;
        let len = vector::length(&reputation.ratings_history);

        while (i < len) {
            let rating = vector::borrow_mut(&mut reputation.ratings_history, i);
            if (rating.reviewer == reviewer && rating.score == old_score) {
                // Update rating
                rating.score = new_score;
                rating.comment = new_comment;
                rating.timestamp = tx_context::epoch(ctx);
                found = true;

                // Update total statistics
                let score_diff = (new_score as u64) - (old_score as u64);
                reputation.total_score = reputation.total_score + score_diff;

                // Recalculate average score
                let new_average = (reputation.total_score * 100) / reputation.total_ratings;
                reputation.average_score = new_average;

                // Update category score
                update_category_score(&mut reputation.category_scores, rating.category, new_score);

                reputation.version = reputation.version + 1;

                // Emit update event
                event::emit(RatingUpdated {
                    agent_id: reputation.agent_registration_id,
                    reviewer,
                    old_score,
                    new_score,
                    new_average,
                });

                break
            };
            i = i + 1;
        };

        assert!(found, 2); // Rating to update not found
    }

    /// Get reputation statistics
    public fun get_reputation_stats(
        reputation: &AgentReputation
    ): (u64, u64, u64, u64) {
        (
            reputation.total_ratings,
            reputation.total_score,
            reputation.average_score,
            reputation.version,
        )
    }

    /// Get average score (converted to floating point representation)
    public fun get_average_score(reputation: &AgentReputation): (u64, u64) {
        (reputation.average_score / 100, reputation.average_score % 100)
    }

    /// Get category scores (returns copy)
    public fun get_category_scores(reputation: &AgentReputation): vector<CategoryScore> {
        let mut result = vector::empty<CategoryScore>();
        let mut i = 0;
        let len = vector::length(&reputation.category_scores);
        while (i < len) {
            vector::push_back(&mut result, *vector::borrow(&reputation.category_scores, i));
            i = i + 1;
        };
        result
    }

    /// Get average score for a specific category
    public fun get_category_score(reputation: &AgentReputation, category: String): Option<u64> {
        let mut i = 0;
        let len = vector::length(&reputation.category_scores);
        while (i < len) {
            let cs = vector::borrow(&reputation.category_scores, i);
            if (cs.category_name == category) {
                return option::some(cs.score)
            };
            i = i + 1;
        };
        option::none()
    }

    /// Get rating history (returns copy)
    public fun get_ratings_history(reputation: &AgentReputation): vector<Rating> {
        let mut result = vector::empty<Rating>();
        let mut i = 0;
        let len = vector::length(&reputation.ratings_history);
        while (i < len) {
            vector::push_back(&mut result, *vector::borrow(&reputation.ratings_history, i));
            i = i + 1;
        };
        result
    }

    /// Get most recent N ratings (returns copy)
    public fun get_recent_ratings(reputation: &AgentReputation, count: u64): vector<Rating> {
        let len = vector::length(&reputation.ratings_history);
        let mut result = vector::empty<Rating>();
        let start = if (count >= len) { 0 } else { len - count };
        let mut i = start;
        while (i < len) {
            vector::push_back(&mut result, *vector::borrow(&reputation.ratings_history, i));
            i = i + 1;
        };
        result
    }

    /// Get ratings from a specific reviewer
    public fun get_reviewer_ratings(reputation: &AgentReputation, reviewer: address): vector<Rating> {
        let mut result = vector::empty<Rating>();
        let mut i = 0;
        let len = vector::length(&reputation.ratings_history);
        while (i < len) {
            let rating = *vector::borrow(&reputation.ratings_history, i);
            if (rating.reviewer == reviewer) {
                vector::push_back(&mut result, rating);
            };
            i = i + 1;
        };
        result
    }

    /// Helper function: update category score
    fun update_category_score(
        category_scores: &mut vector<CategoryScore>,
        category: String,
        score: u8
    ) {
        let mut i = 0;
        let len = vector::length(category_scores);
        let mut found = false;

        while (i < len) {
            let cs = vector::borrow_mut(category_scores, i);
            if (cs.category_name == category) {
                cs.score = score as u64;
                found = true;
                break
            };
            i = i + 1;
        };

        if (!found) {
            vector::push_back(category_scores, CategoryScore { category_name: category, score: (score as u64) });
        }
    }
}