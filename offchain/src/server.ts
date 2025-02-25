import dotenv from "dotenv";
import { ethers } from "ethers";
import { createInstance } from "fhevmjs";
import DoubleABI from "../abi/Double.json" assert { type: "json" };

dotenv.config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL as string;
const CONTRACT_ADDRESS = "0xDf40ba5C2f3541dB15b9ea0B78BE00e22B13e3cE";

// ========== DOUBLE ==========
const PRIVATE_KEY = process.env.PRIVATE_KEY_0 as string; // PRIVATE_KEY_0, PRIVATE_KEY_1, PRIVATE_KEY_2
const NUMBER: number = 9; // NUMBER TO DOUBLE

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
  const contractABI = DoubleABI.abi;
  const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI, wallet);

  console.log("🔐 Creating encrypted input for number...");
  const input = instance.createEncryptedInput(CONTRACT_ADDRESS, wallet.address);

  // NUMBER
  input.add256(NUMBER);

  const encryptedData = await input.encrypt();

  console.log("📝 Wallet address:", wallet.address);

  console.log("🔐 Encrypted input:", encryptedData.handles[0]);
  console.log("🔐 Proof:", encryptedData.inputProof);

  console.log("🔄 Sending transaction...");
  const tx = await contract.setNumber(
    encryptedData.handles[0],
    encryptedData.inputProof,
  );
  await tx.wait();

  console.log(`✅ Encrypted input sent successfully! Tx Hash: ${tx.hash}`);
}

main().catch((error) => {
  console.error("Error:", error);
});
