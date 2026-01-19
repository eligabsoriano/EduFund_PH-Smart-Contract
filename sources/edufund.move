/// EduFund PH - Main module with admin controls and protocol state
module edufund::edufund {
    use sui::event;

    // ===== Errors =====
    const EPaused: u64 = 0;
    const ENotAdmin: u64 = 1;

    // ===== Structs =====
    public struct ProtocolState has key {
        id: UID,
        admin: address,
        paused: bool,
        interest_rate_bps: u64,
        min_advance: u64,
        max_advance: u64,
        schools: vector<address>,
    }

    // ===== Events =====
    public struct ProtocolPaused has copy, drop { paused: bool }
    public struct SchoolAdded has copy, drop { school: address }

    // ===== Init =====
    fun init(ctx: &mut TxContext) {
        transfer::share_object(ProtocolState {
            id: object::new(ctx),
            admin: ctx.sender(),
            paused: false,
            interest_rate_bps: 500,
            min_advance: 1_000_000,
            max_advance: 100_000_000_000,
            schools: vector::empty(),
        });
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    // ===== Admin Functions =====
    public fun pause(state: &mut ProtocolState, ctx: &TxContext) {
        assert!(ctx.sender() == state.admin, ENotAdmin);
        state.paused = true;
        event::emit(ProtocolPaused { paused: true });
    }

    public fun unpause(state: &mut ProtocolState, ctx: &TxContext) {
        assert!(ctx.sender() == state.admin, ENotAdmin);
        state.paused = false;
        event::emit(ProtocolPaused { paused: false });
    }

    public fun set_interest_rate(state: &mut ProtocolState, rate_bps: u64, ctx: &TxContext) {
        assert!(ctx.sender() == state.admin, ENotAdmin);
        state.interest_rate_bps = rate_bps;
    }

    public fun add_school(state: &mut ProtocolState, school: address, ctx: &TxContext) {
        assert!(ctx.sender() == state.admin, ENotAdmin);
        state.schools.push_back(school);
        event::emit(SchoolAdded { school });
    }

    // ===== View Functions =====
    public fun is_paused(state: &ProtocolState): bool { state.paused }
    public fun interest_rate(state: &ProtocolState): u64 { state.interest_rate_bps }
    public fun is_school_approved(state: &ProtocolState, school: address): bool {
        state.schools.contains(&school)
    }
    public fun admin(state: &ProtocolState): address { state.admin }

    public fun assert_not_paused(state: &ProtocolState) {
        assert!(!state.paused, EPaused);
    }
}

