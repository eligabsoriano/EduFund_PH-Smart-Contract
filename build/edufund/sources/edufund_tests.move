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
    fun test_pause_unpause() {
        let mut scenario = ts::begin(ADMIN);
        {
            edufund::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut state = ts::take_shared<ProtocolState>(&scenario);
            edufund::pause(&mut state, scenario.ctx());
            assert!(edufund::is_paused(&state));
            edufund::unpause(&mut state, scenario.ctx());
            assert!(!edufund::is_paused(&state));
            ts::return_shared(state);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_add_school() {
        let mut scenario = ts::begin(ADMIN);
        {
            edufund::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut state = ts::take_shared<ProtocolState>(&scenario);
            edufund::add_school(&mut state, SCHOOL, scenario.ctx());
            assert!(edufund::is_school_approved(&state, SCHOOL));
            ts::return_shared(state);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_student_vault_create_deposit() {
        let mut scenario = ts::begin(PARENT);
        {
            let vault = student_vault::create<SUI>(50_000_000, scenario.ctx());
            assert!(student_vault::goal(&vault) == 50_000_000);
            assert!(student_vault::savings_balance(&vault) == 0);
            transfer::public_transfer(vault, PARENT);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_advance_pool_deposit_withdraw() {
        let mut scenario = ts::begin(LP);
        {
            advance_pool::create_pool<SUI>(scenario.ctx());
        };
        ts::next_tx(&mut scenario, LP);
        {
            let mut pool = ts::take_shared<AdvancePool<SUI>>(&scenario);
            let coin = coin::mint_for_testing<SUI>(1000, scenario.ctx());
            let receipt = advance_pool::deposit(&mut pool, coin, scenario.ctx());
            assert!(advance_pool::available(&pool) == 1000);
            let withdrawn = advance_pool::withdraw(&mut pool, receipt, scenario.ctx());
            assert!(withdrawn.value() == 1000);
            coin::burn_for_testing(withdrawn);
            ts::return_shared(pool);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_repayment_schedule() {
        let mut scenario = ts::begin(PARENT);
        {
            let schedule = repayment_engine::create_schedule(100_000, 500, 3, scenario.ctx());
            assert!(repayment_engine::remaining_balance(&schedule) == 105_000);
            assert!(!repayment_engine::is_fully_paid(&schedule));
            transfer::public_transfer(schedule, PARENT);
        };
        ts::end(scenario);
    }
}
