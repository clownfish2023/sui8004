// Unit tests for agent_nft module

#[test_only]
module trustless_agents::agent_nft_tests;

use std::string::utf8;
use sui::test_scenario;
use trustless_agents::agent_nft::{Self, AgentNFT};

const ADMIN: address = @0xA;
const USER: address = @0xB;

#[test]
fun test_create_agent_and_get_info() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        agent_nft::create_agent(
            1,
            utf8(b"TestAgent"),
            utf8(b"Test Description"),
            utf8(b"https://example.com/image.png"),
            ctx
        );
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let agent = test_scenario::take_from_sender<AgentNFT>(&scenario);
        let (agent_id, name, description, image_url, owner, _created_at, version) = agent_nft::get_agent_info(&agent);
        assert!(agent_id == 1, 0);
        assert!(name == utf8(b"TestAgent"), 1);
        assert!(description == utf8(b"Test Description"), 2);
        assert!(image_url == utf8(b"https://example.com/image.png"), 3);
        assert!(owner == ADMIN, 4);
        assert!(version == 1, 5);
        assert!(agent_nft::is_owner(&agent, ADMIN), 6);
        assert!(!agent_nft::is_owner(&agent, USER), 7);
        test_scenario::return_to_sender(&scenario, agent);
    };
    test_scenario::end(scenario);
}

#[test]
fun test_update_agent() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        agent_nft::create_agent(2, utf8(b"Old"), utf8(b"OldDesc"), utf8(b"http://old"), ctx);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let mut agent = test_scenario::take_from_sender<AgentNFT>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        agent_nft::update_agent(
            &mut agent,
            option::some(utf8(b"NewName")),
            option::none(),
            option::some(utf8(b"https://new.image")),
            ctx
        );
        test_scenario::return_to_sender(&scenario, agent);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let agent = test_scenario::take_from_sender<AgentNFT>(&scenario);
        let (_id, name, description, image_url, _owner, _created_at, version) = agent_nft::get_agent_info(&agent);
        assert!(name == utf8(b"NewName"), 0);
        assert!(description == utf8(b"OldDesc"), 1);
        assert!(image_url == utf8(b"https://new.image"), 2);
        assert!(version == 2, 3);
        test_scenario::return_to_sender(&scenario, agent);
    };
    test_scenario::end(scenario);
}

#[test]
fun test_transfer_agent() {
    let mut scenario = test_scenario::begin(ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        agent_nft::create_agent(3, utf8(b"Transfer"), utf8(b"Desc"), utf8(b"url"), ctx);
    };
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let agent = test_scenario::take_from_sender<AgentNFT>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        agent_nft::transfer_agent(agent, USER, ctx);
    };
    test_scenario::next_tx(&mut scenario, USER);
    {
        // USER received the NFT (take_from_sender succeeds); on-chain owner is USER
        let agent = test_scenario::take_from_sender<AgentNFT>(&scenario);
        let (agent_id, _, _, _, _, _, _) = agent_nft::get_agent_info(&agent);
        assert!(agent_id == 3, 0);
        test_scenario::return_to_sender(&scenario, agent);
    };
    test_scenario::end(scenario);
}
