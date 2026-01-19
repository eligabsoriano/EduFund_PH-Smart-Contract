/// RepaymentEngine - Installment schedules and payment tracking
module edufund::repayment_engine {
    use sui::coin::Coin;
    use sui::event;
    use edufund::advance_pool::{Self, AdvancePool};
    use edufund::student_vault::{Self, StudentVault};

    // ===== Errors =====
    const EInsufficientPayment: u64 = 1;
    const ENotFullyPaid: u64 = 2;

    // ===== Structs =====
    public struct RepaymentSchedule has key, store {
        id: UID,
        borrower: address,
        principal: u64,
        interest: u64,
        total_due: u64,
        installments: u64,
        amount_per_installment: u64,
        paid_count: u64,
        paid_amount: u64,
        start_epoch: u64,
    }

    // ===== Events =====
    public struct ScheduleCreated has copy, drop { borrower: address, total_due: u64, installments: u64 }
    public struct PaymentMade has copy, drop { borrower: address, amount: u64, remaining: u64 }
    public struct LoanClosed has copy, drop { borrower: address, total_paid: u64 }

    // ===== Functions =====
    public fun create_schedule(
        principal: u64,
        interest_rate_bps: u64,
        installments: u64, // 3 or 6 months
        ctx: &mut TxContext
    ): RepaymentSchedule {
        let interest = (principal * interest_rate_bps) / 10000;
        let total = principal + interest;
        let per_installment = total / installments;
        event::emit(ScheduleCreated { borrower: ctx.sender(), total_due: total, installments });
        RepaymentSchedule {
            id: object::new(ctx),
            borrower: ctx.sender(),
            principal,
            interest,
            total_due: total,
            installments,
            amount_per_installment: per_installment,
            paid_count: 0,
            paid_amount: 0,
            start_epoch: ctx.epoch(),
        }
    }

    public fun make_payment<T>(
        schedule: &mut RepaymentSchedule,
        pool: &mut AdvancePool<T>,
        vault: &mut StudentVault<T>,
        coin: Coin<T>,
        _ctx: &TxContext
    ) {
        let amt = coin.value();
        schedule.paid_amount = schedule.paid_amount + amt;
        schedule.paid_count = schedule.paid_count + 1;
        student_vault::record_repayment(vault, amt);
        advance_pool::return_funds(pool, coin);
        event::emit(PaymentMade { 
            borrower: schedule.borrower, 
            amount: amt, 
            remaining: schedule.total_due - schedule.paid_amount 
        });
    }

    public fun early_payoff<T>(
        schedule: &mut RepaymentSchedule,
        pool: &mut AdvancePool<T>,
        vault: &mut StudentVault<T>,
        coin: Coin<T>,
        _ctx: &TxContext
    ) {
        let remaining = schedule.total_due - schedule.paid_amount;
        assert!(coin.value() >= remaining, EInsufficientPayment);
        schedule.paid_amount = schedule.total_due;
        schedule.paid_count = schedule.installments;
        student_vault::record_repayment(vault, remaining);
        advance_pool::return_funds(pool, coin);
        event::emit(PaymentMade { borrower: schedule.borrower, amount: remaining, remaining: 0 });
    }

    public fun close(schedule: RepaymentSchedule) {
        assert!(schedule.paid_amount >= schedule.total_due, ENotFullyPaid);
        event::emit(LoanClosed { borrower: schedule.borrower, total_paid: schedule.paid_amount });
        let RepaymentSchedule { id, .. } = schedule;
        object::delete(id);
    }

    public fun remaining_balance(s: &RepaymentSchedule): u64 { s.total_due - s.paid_amount }
    public fun is_fully_paid(s: &RepaymentSchedule): bool { s.paid_amount >= s.total_due }
    public fun paid_installments(s: &RepaymentSchedule): u64 { s.paid_count }
}
