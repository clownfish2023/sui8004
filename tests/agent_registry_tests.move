// Unit tests for agent_registry module

#[test_only]
module trustless_agents::agent_registry_tests;

use sui::test_scenario;
use trustless_agents::agent_registry::{Self, Registry};

const ADMIN: address = @0xA;

#[test]
fun test_init_registry_and_stats() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        agent_registry::init_registry(ctx);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let registry = test_scenario::take_shared<Registry>(&scenario);
        let (next_id, total) = agent_registry::get_registry_stats(&registry);
        assert!(next_id == 1, 0);
        assert!(total == 0, 1);
        test_scenario::return_shared(registry);
    };
    test_scenario::end(scenario);
}
