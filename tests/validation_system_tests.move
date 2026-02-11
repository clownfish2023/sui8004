// Unit tests for validation_system module

#[test_only]
module trustless_agents::validation_system_tests;

use sui::test_scenario;
use trustless_agents::validation_system::{Self, StakePool, AgentValidation};

const ADMIN: address = @0xA;

#[test]
fun test_init_stake_pool_and_create_validation() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        validation_system::init_stake_pool(ctx);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let pool = test_scenario::take_shared<StakePool>(&scenario);
        let (total_staked, _balance) = validation_system::get_stake_pool_stats(&pool);
        assert!(total_staked == 0, 0);
        test_scenario::return_shared(pool);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        validation_system::create_agent_validation(@0x1, ADMIN, ctx);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let validation = test_scenario::take_shared<AgentValidation>(&scenario);
        assert!(!validation_system::is_validated(&validation), 0);
        test_scenario::return_shared(validation);
    };
    test_scenario::end(scenario);
}
