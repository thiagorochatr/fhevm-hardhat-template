# Voting System

Private Voting System using FHEVM.

## Overview

#### `VotingSystem.sol`

Main voting contract implementing FHE-based private voting with encrypted vote casting, vote counting, and vote revelation. The contract allows creating votes with multiple candidates, casting encrypted votes that preserve voter privacy, and revealing final vote tallies after voting period ends.

#### `IdentityManager.sol`

Manages voter identity verification and generates unique IDs for authorized voters, maintaining a list of allowed addresses.
It is a mocked way to simulate user verification. In the future, verification using ZKP will be implemented.

### /off-chain

Performs transactions to vote, passing the voting ID, and the encrypted vote
