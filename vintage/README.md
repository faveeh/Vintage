# Vintago 🍷

**A Decentralized Rare Wine Investment Club**  
Enable fractional ownership of premium wine vintages, automated profit distribution, and community-driven tasting events on the Stacks blockchain.

---

## 🚀 Overview

**Vintago** is a smart contract that brings fine wine investment to the decentralized world. It allows collectors to:

- Register premium wine vintages.
- Buy fractional units of ownership.
- Earn annual profits from wine holdings.
- Vote on and host wine tasting events.
- Claim profit shares securely and transparently.

---

## 📦 Features

### ✅ Vintage Management
- `register-vintage`: Register a new wine collection by the Cellar Master.
- `get-vintage`: Fetch wine details.

### 🍇 Unit Ownership
- `purchase-units`: Buy shares of a wine vintage.
- `get-unit-balance`: Check your share in a wine vintage.

### 💰 Profit Distribution
- `distribute-profits`: Trigger annual profit distribution (by the sommelier).
- `claim-profit`: Collect your share of profits for a specific year.
- `calculate-profit-share`: Estimate your expected profit for a vintage.

### 🥂 Tasting Governance
- `create-tasting`: Propose a wine tasting event.
- `vote-tasting`: Vote on proposed tasting events with your ownership weight.
- `get-tasting`: Fetch tasting event details.

---

## 🔐 Roles & Permissions

- **CELLAR_MASTER**: Only this account can register new vintages.
- **SOMMELIER**: Assigned to each vintage; only they can initiate profit distributions.
- **Collectors**: Any user who owns units of a vintage. Only collectors can propose or vote on tastings.

---

## ⚠️ Error Codes

| Code | Meaning                        |
|------|--------------------------------|
| 500  | Unauthorized collector         |
| 501  | Insufficient wine units owned |
| 502  | Vintage not found              |
| 503  | Invalid amount                 |
| 504  | Tasting event not found        |
| 505  | Already voted on this tasting  |

---

## 🛠️ Developer Notes

- Built with [Clarity](https://docs.stacks.co/docs/clarity/overview/), optimized for transparent smart contract logic.
- Uses `block-height` for tasting event deadlines.
- Profit shares are computed based on unit ownership at the time of claiming.

---

## 👨‍🔬 Future Enhancements

- NFT representation of wine units.
- Wine vault certification oracles.
- Integration with off-chain delivery and storage logistics.
