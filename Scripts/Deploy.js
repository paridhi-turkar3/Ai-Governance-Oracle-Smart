const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying AiGovernanceOracle Smart...");

  // Get the ContractFactory and Signers here.
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const AiGovernanceOracle = await ethers.getContractFactory("AiGovernanceOracle");
  const aiGovernanceOracle = await AiGovernanceOracle.deploy();

  await aiGovernanceOracle.deployed();

  console.log("AiGovernanceOracle Smart deployed to:", aiGovernanceOracle.address);
  console.log("Transaction hash:", aiGovernanceOracle.deployTransaction.hash);

  // Wait for a few block confirmations
  console.log("Waiting for block confirmations...");
  await aiGovernanceOracle.deployTransaction.wait(6);
  console.log("Contract confirmed on Core Blockchain!");

  // Log initial configuration
  console.log("\n=== Initial Configuration ===");
  console.log("Admin address:", await aiGovernanceOracle.admin());
  console.log("Proposal count:", await aiGovernanceOracle.proposalCount());
  console.log("Quorum percentage:", await aiGovernanceOracle.quorumPercentage());
  console.log("Total voting power:", await aiGovernanceOracle.totalVotingPower());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
