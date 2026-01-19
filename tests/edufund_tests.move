#[test_only]
module edufund::edufund_tests {
    use sui::test_scenario as ts;
    use sui::coin;
    use sui::sui::SUI;
    use edufund::edufund::{Self, ProtocolState};
    use edufund::advance_pool::{Self, AdvancePool};
    use edufund::student_vault;
    use edufund::repayment_engine;

    const ADMIN: address = @0xAD;
    const LP: address = @0x1234;
    const PARENT: address = @0xFA;
    const SCHOOL: address = @0x5C;

    #[test]
    fun test_protocol_init() {
        let mut scenario = ts::begin(ADMIN);
        {
            edufund::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, ADMIN);
        {
            let state = ts::take_shared<ProtocolState>(&scenario);
            assert!(!edufund::is_paused(&state));
            assert!(edufund::interest_rate(&state) == 500);
            assert!(edufund::admin(&state) == ADMIN);
            ts::return_shared(state);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_add_pool() {
        let mut scenario = ts::begin(LP);
        {
            advance_pool::create_pool_for_testing<SUI>(scenario.ctx());
        };
        ts::next_tx(&mut scenario, LP);
        {
            let pool = ts::take_shared<AdvancePool<SUI>>(&scenario);
            assert!(advance_pool::available(&pool) == 0);
            ts::return_shared(pool);
        };
        ts::end(scenario);
    }
}
