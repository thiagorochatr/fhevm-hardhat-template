import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const args = [100];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const deployed = await deploy("MyConfidentialERC20", {
    from: deployer,
    args: args,
    log: true,
  });

  console.log(`MyConfidentialERC20 CONTRACT DEPLOYED: `, deployed.address);

  // console.log(`Transaction hash: `, deployed.transactionHash);
  // // Wait for 5 block confirmations before verifying
  // const txReceipt = await hre.ethers.provider.getTransactionReceipt(deployed.transactionHash!);
  // if (txReceipt) {
  //   console.log("Waiting for 5 confirmations...");
  //   await hre.ethers.provider.waitForTransaction(deployed.transactionHash!, 5);
  // }

  // // Add verification
  // await run("verify:verify", {
  //   address: deployed.address,
  //   constructorArguments: args,
  // });

  // console.log(`MyConfidentialERC20 CONTRACT VERIFIED`);
};
export default func;
func.id = "deploy_confidentialERC20"; // id required to prevent reexecution
func.tags = ["MyConfidentialERC20"];
