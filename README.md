# voting
# 🗳️ On-Chain Voting DApp (Clarity + Clarinet)

A **fully transparent, decentralized voting system** built on the Stacks blockchain.  
This project demonstrates how governance can be implemented **entirely on-chain** with no centralized servers.

---

## ✨ Features
- ✅ **Proposal Creation** — anyone can create a proposal with a title (up to 100 chars).  
- ✅ **Open Voting** — all users can cast a **Yes/No** vote.  
- ✅ **Fairness** — each user can vote **only once per proposal**.  
- ✅ **On-Chain Results** — votes are permanently stored on-chain.  
- ✅ **Proposal Lifecycle** — proposals can be **closed** by their creator, locking results forever.  

---

## 🚀 Why It’s Attractive
- 🎯 **Universal Use Case**: Governance, DAOs, community polls, hackathons.  
- 🔍 **Transparency**: Anyone can verify results directly on-chain.  
- 🛡️ **No Errors**: Lightweight, clean, and passes `clarinet check` on first run.  
- 🎁 **Demo-Friendly**: Easy to showcase live — create, vote, close, view results.  

This makes it a **perfect raffle or competition entry** — eye-catching, useful, and super clear.

---

## 📖 How It Works

### 1. Create a Proposal
```clarity
(contract-call? .voting create-proposal "Should we add a community fund?")
 
