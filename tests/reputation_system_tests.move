// Unit tests for reputation_system module

#[test_only]
module trustless_agents::reputation_system_tests;

use std::string::utf8;
use sui::test_scenario;
use trustless_agents::reputation_system::{Self, AgentReputation};

const ADMIN: address = @0xA;
const REVIEWER: address = @0xB;

#[test]
fun test_create_reputation_and_add_rating() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::create_agent_reputation(@0x1, ADMIN, ctx);
    };
    test_scenario::next_tx(&mut scenario, REVIEWER);
    {
        let mut reputation = test_scenario::take_shared<AgentReputation>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::add_rating(
            &mut reputation,
            8,
            option::some(utf8(b"Good")),
            utf8(b"performance"),
            ctx
        );
        test_scenario::return_shared(reputation);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let reputation = test_scenario::take_shared<AgentReputation>(&scenario);
        let (total_ratings, total_score, average_score, _) = reputation_system::get_reputation_stats(&reputation);
        assert!(total_ratings == 1, 0);
        assert!(total_score == 8, 1);
        assert!(average_score == 800, 2); // 8.00 as u64*100
        test_scenario::return_shared(reputation);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = 1, location = trustless_agents::reputation_system)]
fun test_add_rating_invalid_score_zero() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::create_agent_reputation(@0x1, ADMIN, ctx);
    };
    test_scenario::next_tx(&mut scenario, REVIEWER);
    {
        let mut reputation = test_scenario::take_shared<AgentReputation>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::add_rating(&mut reputation, 0, option::none(), utf8(b"perf"), ctx);
        test_scenario::return_shared(reputation);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = 1, location = trustless_agents::reputation_system)]
fun test_add_rating_invalid_score_eleven() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::create_agent_reputation(@0x1, ADMIN, ctx);
    };
    test_scenario::next_tx(&mut scenario, REVIEWER);
    {
        let mut reputation = test_scenario::take_shared<AgentReputation>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        reputation_system::add_rating(&mut reputation, 11, option::none(), utf8(b"perf"), ctx);
        test_scenario::return_shared(reputation);
    };
    test_scenario::end(scenario);
}
