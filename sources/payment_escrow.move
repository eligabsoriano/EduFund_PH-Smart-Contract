/// PaymentEscrow - Secure fund release to approved schools
module edufund::payment_escrow {
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;
    use sui::event;
    use edufund::edufund::{Self, ProtocolState};

    // ===== Errors =====
    const ESchoolNotApproved: u64 = 0;
    const EAlreadyReleased: u64 = 1;

    // ===== Structs =====
    public struct Escrow<phantom T> has key {
        id: UID,
        borrower: address,
        school: address,
        funds: Balance<T>,
        released: bool,
    }

    public struct PaymentProof has key, store {
        id: UID,
        borrower: address,
        school: address,
        amount: u64,
        timestamp: u64,
    }

    // ===== Events =====
    public struct EscrowCreated<phantom T> has copy, drop { borrower: address, school: address, amount: u64 }
    public struct FundsReleased<phantom T> has copy, drop { school: address, amount: u64 }

    // ===== Entry Functions =====
    entry fun create_escrow<T>(
        state: &ProtocolState,
        coin: Coin<T>,
        school: address,
        ctx: &mut TxContext
    ) {
        edufund::assert_not_paused(state);
        assert!(edufund::is_school_approved(state, school), ESchoolNotApproved);
        let amt = coin.value();
        event::emit(EscrowCreated<T> { borrower: ctx.sender(), school, amount: amt });
        let escrow = Escrow {
            id: object::new(ctx),
            borrower: ctx.sender(),
            school,
            funds: coin.into_balance(),
            released: false,
        };
        transfer::transfer(escrow, ctx.sender());
    }

    entry fun release_to_school<T>(escrow: Escrow<T>, ctx: &mut TxContext) {
        assert!(!escrow.released, EAlreadyReleased);
        let Escrow { id, borrower, school, funds, released: _ } = escrow;
        let amt = funds.value();
        event::emit(FundsReleased<T> { school, amount: amt });
        let coin = coin::from_balance(funds, ctx);
        transfer::public_transfer(coin, school);
        let proof = PaymentProof {
            id: object::new(ctx),
            borrower,
            school,
            amount: amt,
            timestamp: ctx.epoch(),
        };
        transfer::public_transfer(proof, borrower);
        object::delete(id);
    }

    // ===== View Functions =====
    public fun is_released<T>(escrow: &Escrow<T>): bool { escrow.released }
    public fun escrow_amount<T>(escrow: &Escrow<T>): u64 { escrow.funds.value() }
}
