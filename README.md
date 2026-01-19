# EduFund PH - Smart Contract

A decentralized tuition advance & education savings protocol on **Sui blockchain**.

## Overview

EduFund PH enables:
- **Tuition Advances**: Short-term USDC advances sent directly to approved schools
- **Education Savings**: Goal-based savings buckets for families
- **Transparent Repayments**: Fixed installments with no early repayment penalties

## Architecture

| Module | Purpose |
|--------|---------|
| `edufund.move` | Admin controls, protocol state, emergency pause |
| `advance_pool.move` | Liquidity pool for tuition advances |
| `student_vault.move` | Individual savings and tracking |
| `payment_escrow.move` | Secure school payments with on-chain proofs |
| `repayment_engine.move` | Installment schedules and repayment tracking |

## Build & Test

```bash
# Build
sui move build

# Test
sui move test

# Deploy to testnet
sui client publish --gas-budget 100000000
```

## Key Features

- ✅ Gas-optimized minimal code
- ✅ Simple interest (no compounding)
- ✅ Early repayment without penalty
- ✅ School whitelist for fund security
- ✅ Emergency pause mechanism

## License

MIT