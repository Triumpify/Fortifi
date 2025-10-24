# Bug Bounty Hunter Rewards Smart Contract

## Overview
This Clarity smart contract manages a bug bounty program for security researchers. It allows a security chief to certify hunters, award badges, set bounty rewards, and manage the claims process.

## Features
- **Hunter Certification**: Security chief can certify and revoke hunter certifications
- **Security Badges**: Award badges to hunters as additional credentials
- **Bounty Management**: Set individual bounty rewards for hunters
- **Batch Processing**: Process multiple bounty payouts efficiently
- **Claims Control**: Toggle bounty claims on/off
- **Comprehensive Profiles**: View detailed hunter information

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `security-chief` | tx-sender | The contract deployer (security chief) |
| `err-chief-only` | u100 | Only security chief can perform this action |
| `err-bounty-claimed` | u101 | Bounty already claimed |
| `err-not-certified` | u102 | Hunter not certified |
| `err-no-bounty-assigned` | u103 | No bounty assigned to hunter |
| `err-claims-frozen` | u104 | Claims are currently frozen |
| `err-invalid-hunter` | u105 | Invalid hunter address |
| `err-invalid-bounty` | u106 | Invalid bounty amount |

## Data Storage

### Data Variables
- `total-bounty-treasury`: Total bounty pool (initialized to 5,000,000)
- `claims-available`: Boolean flag to enable/disable claims

### Data Maps
- `hunter-bounties`: Maps hunter addresses to their bounty rewards
- `bounty-claims`: Tracks which hunters have claimed their bounties
- `security-badges`: Tracks badge holders
- `certified-hunters`: Tracks certified bug hunters

## Public Functions

### Security Chief Only

#### `certify-hunter`
```clarity
(certify-hunter (hunter principal))
```
Certify a hunter to participate in the bounty program.

#### `revoke-certification`
```clarity
(revoke-certification (hunter principal))
```
Revoke a hunter's certification.

#### `award-badge`
```clarity
(award-badge (hunter principal) (has-badge bool))
```
Award or remove a security badge from a hunter.

#### `set-bounty-reward`
```clarity
(set-bounty-reward (hunter principal) (reward uint))
```
Assign a bounty reward to a hunter. Reward must be greater than 0 and not exceed treasury balance.

#### `batch-bounty-payout`
```clarity
(batch-bounty-payout (hunters (list 200 principal)) (rewards (list 200 uint)))
```
Process multiple bounty assignments at once. Lists must be equal length.

#### `toggle-claims`
```clarity
(toggle-claims)
```
Enable or disable bounty claims globally.

### Public Functions

#### `claim-bounty`
```clarity
(claim-bounty)
```
Allow a certified hunter to claim their assigned bounty. Requirements:
- Claims must be available (not frozen)
- Hunter must be certified AND have a security badge
- Hunter must have an assigned bounty
- Bounty must not have been claimed already

## Read-Only Functions

#### `get-bounty-reward`
```clarity
(get-bounty-reward (hunter principal)) → uint
```
Returns the bounty amount assigned to a hunter.

#### `has-claimed-bounty`
```clarity
(has-claimed-bounty (hunter principal)) → bool
```
Check if a hunter has claimed their bounty.

#### `check-certification`
```clarity
(check-certification (hunter principal)) → bool
```
Verify if a hunter is fully certified (has both certification AND badge).

#### `are-claims-available`
```clarity
(are-claims-available) → bool
```
Check if claims are currently enabled.

#### `get-treasury-balance`
```clarity
(get-treasury-balance) → uint
```
Get the total treasury balance.

#### `get-hunter-profile`
```clarity
(get-hunter-profile (hunter principal)) → response
```
Returns comprehensive hunter information:
```clarity
{
    bounty: uint,           // Assigned bounty amount
    claimed: bool,          // Whether bounty was claimed
    certified: bool,        // Full certification status
    is-certified: bool,     // Has hunter certification
    has-badge: bool,        // Has security badge
    can-claim: bool         // Eligible to claim now
}
```

## Workflow

### For Security Chief
1. Deploy contract (becomes security-chief)
2. Certify hunters: `(certify-hunter hunter-address)`
3. Award badges: `(award-badge hunter-address true)`
4. Set bounties: `(set-bounty-reward hunter-address amount)`
5. Enable claims: `(toggle-claims)`

### For Hunters
1. Get certified by security chief
2. Receive security badge
3. Wait for bounty assignment
4. Wait for claims to be enabled
5. Call `(claim-bounty)` to receive reward

## Security Considerations

- Only the contract deployer can perform administrative functions
- Hunters must have BOTH certification AND badge to claim
- Claims can be frozen by security chief for security purposes
- Bounties can only be claimed once
- Hunter addresses are validated to prevent invalid assignments
- Security chief cannot assign bounties to themselves

## Example Usage

```clarity
;; Security chief certifies a hunter
(contract-call? .bounty-contract certify-hunter 'ST1HUNTER123)

;; Security chief awards badge
(contract-call? .bounty-contract award-badge 'ST1HUNTER123 true)

;; Security chief sets bounty
(contract-call? .bounty-contract set-bounty-reward 'ST1HUNTER123 u50000)

;; Security chief enables claims
(contract-call? .bounty-contract toggle-claims)

;; Hunter claims bounty
(contract-call? .bounty-contract claim-bounty)

;; Check hunter profile
(contract-call? .bounty-contract get-hunter-profile 'ST1HUNTER123)
```
