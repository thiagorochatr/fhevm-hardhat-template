import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log("OLHA EU AQUI");
  await new Promise((resolve) => setTimeout(resolve, 10000));
};

export default func;
func.id = "deploy_1"; // id required to prevent reexecution
func.tags = ["deploy_1"];
