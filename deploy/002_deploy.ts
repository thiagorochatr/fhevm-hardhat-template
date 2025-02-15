import { run } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  /// wallets that will be allowed to vote
  const args = [[deployer, process.env.WALLET_TEST_1!, process.env.WALLET_TEST_2!]];

  const deployed = await deploy("VotingSystem", {
    from: deployer,
    args: args,
    log: true,
  });

  console.log(`VotingSystem CONTRACT DEPLOYED: `, deployed.address);

  console.log("Waiting 30 seconds before verification...");
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
