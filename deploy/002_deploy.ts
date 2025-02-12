import { run } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const args = [100, [deployer]];

  const deployed = await deploy("VotingSystem", {
    from: deployer,
    args: args,
    log: true,
  });

  console.log(`VotingSystem CONTRACT DEPLOYED: `, deployed.address);

  // console.log(`Transaction hash: `, deployed.transactionHash);
  // Wait for 5 block confirmations before verifying
  // const txReceipt = await hre.ethers.provider.getTransactionReceipt(deployed.transactionHash!);
  // if (txReceipt) {
  //   console.log("Waiting for 5 confirmations...");
  //   await hre.ethers.provider.waitForTransaction(deployed.transactionHash!, 5);
  // }

  console.log("Waiting 60 seconds before verification...");
  await new Promise((resolve) => setTimeout(resolve, 30000));

  // Add verification
  await run("verify:verify", {
    address: deployed.address,
    constructorArguments: args,
  });

  console.log(`VotingSystem CONTRACT VERIFIED`);
};
export default func;
func.id = "deploy_votingSystem"; // id required to prevent reexecution
func.tags = ["VotingSystem"];
