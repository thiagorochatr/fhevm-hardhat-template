import dotenv from "dotenv";
import { ethers } from "ethers";
import { createInstance } from "fhevmjs";
import VotingSystemABI from "../../artifacts/contracts/VotingSystem.sol/VotingSystem.json" assert { type: "json" };

dotenv.config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL as string;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS as string;

// ========== VOTING ==========
const PRIVATE_KEY = process.env.PRIVATE_KEY_0 as string; // PRIVATE_KEY_0, PRIVATE_KEY_1, PRIVATE_KEY_2
const VOTE_CHOICE: number = 0;
const VOTE_ID: number = 0;

if (!SEPOLIA_RPC_URL || !PRIVATE_KEY || !CONTRACT_ADDRESS) {
  throw new Error("Please set the environment variables correctly.");
}

async function main() {
  const instance = await createInstance({
    networkUrl: process.env.NETWORK_URL as string,
    gatewayUrl: process.env.GATEWAY_URL as string,
    kmsContractAddress: process.env.KMS_CONTRACT_ADDRESS as string,
    aclContractAddress: process.env.ACL_CONTRACT_ADDRESS as string,
  });

  // Configure provider and wallet
  const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  // Connect to contract
  const contractABI = VotingSystemABI.abi;
  const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI, wallet);

  console.log("🔐 Creating encrypted input for vote...");
  const input = instance.createEncryptedInput(CONTRACT_ADDRESS, wallet.address);

  // VOTE CHOICE (index of the candidate array)
  input.add64(VOTE_CHOICE);

  const encryptedData = await input.encrypt();

  console.log("📝 Wallet address:", wallet.address);

  console.log("🔐 Encrypted input:", encryptedData.handles[0]);
  console.log("🔐 Proof:", encryptedData.inputProof);

  console.log("🔄 Sending transaction...");
  const tx = await contract.castVote(
    VOTE_ID,
    encryptedData.handles[0],
    encryptedData.inputProof,
  );
  await tx.wait();

  console.log(`✅ Encrypted input sent successfully! Tx Hash: ${tx.hash}`);
}

main().catch((error) => {
  console.error("Error:", error);
});
