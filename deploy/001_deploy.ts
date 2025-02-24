import { run } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const args: string[] = [];

  const deployed = await deploy("Double", {
    from: deployer,
    args: args,
    log: true,
  });

  console.log(`Double contract: `, deployed.address);

  console.log("Waiting 30 seconds before verification...");
  await new Promise((resolve) => setTimeout(resolve, 30000));

  // Add verification
  await run("verify:verify", {
    address: deployed.address,
    constructorArguments: args,
  });

  console.log(`Double CONTRACT VERIFIED`);
};
export default func;
func.id = "deploy_double"; // id required to prevent reexecution
func.tags = ["Double"];
