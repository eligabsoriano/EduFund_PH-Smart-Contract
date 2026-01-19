/// StudentVault - Individual savings and advance tracking
module edufund::student_vault {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;

    // ===== Errors =====
    const EInsufficientSavings: u64 = 0;

    // ===== Structs =====
    public struct StudentVault<phantom T> has key, store {
        id: UID,
        owner: address,
        savings: Balance<T>,
        goal: u64,
        total_repaid: u64,
    }

    // ===== Events =====
    public struct VaultCreated has copy, drop { owner: address, goal: u64 }
    public struct SavingsDeposited<phantom T> has copy, drop { owner: address, amount: u64 }
    public struct SavingsWithdrawn<phantom T> has copy, drop { owner: address, amount: u64 }

    // ===== Functions =====
    public fun create<T>(goal: u64, ctx: &mut TxContext): StudentVault<T> {
        let owner = ctx.sender();
        event::emit(VaultCreated { owner, goal });
        StudentVault {
            id: object::new(ctx),
            owner,
            savings: balance::zero(),
            goal,
            total_repaid: 0,
        }
    }

    public fun deposit<T>(vault: &mut StudentVault<T>, coin: Coin<T>, _ctx: &TxContext) {
        let amt = coin.value();
        vault.savings.join(coin.into_balance());
        event::emit(SavingsDeposited<T> { owner: vault.owner, amount: amt });
    }

    public fun withdraw<T>(vault: &mut StudentVault<T>, amount: u64, ctx: &mut TxContext): Coin<T> {
        assert!(vault.savings.value() >= amount, EInsufficientSavings);
        event::emit(SavingsWithdrawn<T> { owner: vault.owner, amount });
        coin::from_balance(vault.savings.split(amount), ctx)
    }

    public fun record_repayment<T>(vault: &mut StudentVault<T>, amount: u64) {
        vault.total_repaid = vault.total_repaid + amount;
    }

    public fun savings_balance<T>(vault: &StudentVault<T>): u64 { vault.savings.value() }
    public fun goal<T>(vault: &StudentVault<T>): u64 { vault.goal }
    public fun progress_pct<T>(vault: &StudentVault<T>): u64 {
        if (vault.goal == 0) { 100 } else { (vault.savings.value() * 100) / vault.goal }
    }
}
