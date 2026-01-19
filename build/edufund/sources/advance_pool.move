/// AdvancePool - Liquidity pool for tuition advances
module edufund::advance_pool {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;

    // ===== Errors =====
    const EInsufficientLiquidity: u64 = 0;
    const EInsufficientBalance: u64 = 1;

    // ===== Structs =====
    public struct AdvancePool<phantom T> has key {
        id: UID,
        balance: Balance<T>,
        total_advances: u64,
    }

    public struct LPReceipt<phantom T> has key, store {
        id: UID,
        amount: u64,
    }

    // ===== Events =====
    public struct LiquidityAdded<phantom T> has copy, drop { amount: u64, provider: address }
    public struct LiquidityRemoved<phantom T> has copy, drop { amount: u64, provider: address }
    public struct AdvanceTaken<phantom T> has copy, drop { amount: u64, borrower: address }

    // ===== Functions =====
    public fun create_pool<T>(ctx: &mut TxContext) {
        transfer::share_object(AdvancePool<T> {
            id: object::new(ctx),
            balance: balance::zero(),
            total_advances: 0,
        });
    }

    public fun deposit<T>(pool: &mut AdvancePool<T>, coin: Coin<T>, ctx: &mut TxContext): LPReceipt<T> {
        let amt = coin.value();
        pool.balance.join(coin.into_balance());
        event::emit(LiquidityAdded<T> { amount: amt, provider: ctx.sender() });
        LPReceipt { id: object::new(ctx), amount: amt }
    }

    public fun withdraw<T>(pool: &mut AdvancePool<T>, receipt: LPReceipt<T>, ctx: &mut TxContext): Coin<T> {
        let LPReceipt { id, amount } = receipt;
        object::delete(id);
        assert!(pool.balance.value() >= amount, EInsufficientBalance);
        event::emit(LiquidityRemoved<T> { amount, provider: ctx.sender() });
        coin::from_balance(pool.balance.split(amount), ctx)
    }

    public fun take_advance<T>(pool: &mut AdvancePool<T>, amount: u64, ctx: &mut TxContext): Coin<T> {
        assert!(pool.balance.value() >= amount, EInsufficientLiquidity);
        pool.total_advances = pool.total_advances + amount;
        event::emit(AdvanceTaken<T> { amount, borrower: ctx.sender() });
        coin::from_balance(pool.balance.split(amount), ctx)
    }

    public fun return_funds<T>(pool: &mut AdvancePool<T>, coin: Coin<T>) {
        pool.balance.join(coin.into_balance());
    }

    public fun available<T>(pool: &AdvancePool<T>): u64 { pool.balance.value() }
}
