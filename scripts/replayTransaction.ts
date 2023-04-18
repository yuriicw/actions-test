import { artifacts, ethers, network } from "hardhat";
import { ContractFactory } from "ethers";
import { Artifact } from "hardhat/src/types/artifacts";
import { Provider } from "@ethersproject/providers";
import { ErrorDescription } from "@ethersproject/abi/src.ts/interface";
import { Result } from "@ethersproject/abi";
import * as dotenv from 'dotenv';

dotenv.config();


// Script input parameters
const txHash: string = process.env.HASH || "";
const rpcUrl: string = process.env.RPC || "";

// Script parameters
const textLevelIndent = "  ";

interface ContractEntity {
  artifact: Artifact;
  contractFactory: ContractFactory;
}

function panicErrorCodeToReason(errorCode: number): string {
  switch (errorCode) {
    case 0x1:
      return "Assertion error";
    case 0x11:
      return "Arithmetic operation underflowed or overflowed outside of an unchecked block";
    case 0x12:
      return "Division or modulo division by zero";
    case 0x21:
      return "Tried to convert a value into an enum, but the value was too big or negative";
    case 0x22:
      return "Incorrectly encoded storage byte array";
    case 0x31:
      return ".pop() was called on an empty array";
    case 0x32:
      return "Array accessed at an out-of-bounds or negative index";
    case 0x41:
      return "Too much memory was allocated, or an array was created that is too large";
    case 0x51:
      return "Called a zero-initialized variable of internal function type";
    default:
      return "???";
  }
}

async function getDeployableContractEntities(): Promise<ContractEntity[]> {
  const contractFullNames: string[] = await artifacts.getAllFullyQualifiedNames();
  const deployableContractEntities: ContractEntity[] = [];
  for (let contractFullName of contractFullNames) {
    const artifact: Artifact = await artifacts.readArtifact(contractFullName);
    if (artifact.bytecode !== "0x") {
      const contractFactory: ContractFactory = await ethers.getContractFactory(contractFullName);
      deployableContractEntities.push({artifact, contractFactory});
    }
  }
  return deployableContractEntities;
}

async function decodeCustomErrorData(errorData: string): Promise<string[]> {
  const deployableContractEntites = await getDeployableContractEntities();
  const decodedCustomErrorStrings: string[] = [];

  deployableContractEntites.forEach(contractEntity => {
    try {
      const errorDescription: ErrorDescription = contractEntity.contractFactory.interface.parseError(errorData);
      const decodedArgs: string = errorDescription.args.map(arg => {
        const argString = arg.toString();
        if (argString.startsWith("0x")) {
          return `"${argString}"`;
        } else {
          return argString;
        }
      }).join(", ");
      const contractName = contractEntity.artifact.contractName;
      const decodedError = `${errorDescription.errorFragment.name}(${decodedArgs}) -- from contract "${contractName}"`;
      decodedCustomErrorStrings.push(decodedError);
    } catch (e) {
      //do nothing;
    }
  });

  return decodedCustomErrorStrings;
}

function decodeRevertMessage(errorData: string): string {
  const content = `0x${errorData.substring(10)}`;
  const reason: Result = ethers.utils.defaultAbiCoder.decode(["string"], content);
  return `Reverted with the message: "${reason[0]}".`;
}

function decodePanicCode(errorData: string): string {
  const content = `0x${errorData.substring(10)}`;
  const code: Result = ethers.utils.defaultAbiCoder.decode(["uint"], content);
  const codeHex: string = code[0].toHexString();
  const reason: string = panicErrorCodeToReason(code[0].toNumber());
  return `Panicked with the code: "${codeHex}"(${reason}).`;
}

async function decodeErrorData(errorData: string, textIndent: string): Promise<string> {
  const nextLevelTextIndent = textIndent + textLevelIndent;
  const decodedCustomErrorStrings = await decodeCustomErrorData(errorData);
  let result: string;
  let isCustomErrorOnly = false;

  if (errorData.startsWith("0x08c379a0")) { // decode Error(string)
    result = textIndent + decodeRevertMessage(errorData);
  } else if (errorData.startsWith("0x4e487b71")) { // decode Panic(uint)
    result = textIndent + decodePanicCode(errorData);
  } else {
    isCustomErrorOnly = true;
    if (decodedCustomErrorStrings.length > 0) {
      result = textIndent + "Reverted with a custom error (or several suitable ones):\n" +
        nextLevelTextIndent + decodedCustomErrorStrings.join("\n" + nextLevelTextIndent);
    } else {
      result = textIndent + "Reverted with a custom error that can't be decoded using the provided contracts.\n" +
        textIndent + `Try to add more contract(s) to the "contracts" directory to get decoded error.`;
    }
  }
  if (!isCustomErrorOnly) {
    if (decodedCustomErrorStrings.length > 0) {
      result += ` Also it can be the following custom error(s):\n` + nextLevelTextIndent +
        decodedCustomErrorStrings.join("\n" + nextLevelTextIndent);
    }
  }
  return result;
}


async function main() {
  console.log(`🏁 Replaying the transaction with hash`, txHash, "...");
  const textIndent1 = textLevelIndent;
  const textIndent2 = textIndent1 + textLevelIndent;
  const textIndent3 = textIndent2 + textLevelIndent;
  console.log(textIndent1 + `👉 Original network RPC URL:`, rpcUrl);
  const provider: Provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  console.log("");

  console.log(textIndent1 + "🏁 Getting the transaction response from the original network ...");
  const txResponse = await provider.getTransaction(txHash);

  if (!txResponse) {
    console.log(textIndent1 + "⛔ The transaction with the provided hash does not exist.");
    return;
  }
  if (!txResponse.blockNumber) {
    console.log(textIndent1 + "⛔ The transaction with the provided hash has not been minted yet.");
    return;
  }
  if (!txResponse.raw) {
    console.log(textIndent1 + "⛔ The transaction does not have the raw data with the signature. Check the RPC!");
    return;
  }
  console.log(textIndent1 + "✅ The transaction has been gotten successfully:");
  console.log(textIndent2 + "👉 The block number of the transaction in the original chain:", txResponse.blockNumber);
  console.log(textIndent2 + "👉 The raw data of the signed transaction:", txResponse.raw);
  console.log("");

  const previousBlockNumber = txResponse.blockNumber - 1;
  console.log(textIndent1 + "🏁 Resetting the Hardhat network with forking for the previous block ...");
  await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: rpcUrl,
          blockNumber: previousBlockNumber,
        },
      },
    ],
  });
  console.log(textIndent1 + "✅ The resetting has done successfully. The current block:", previousBlockNumber);
  console.log("");

  console.log(textIndent1 + "🏁 Minting the block", previousBlockNumber, "...");
  await ethers.provider.send("evm_mine", []);
  console.log(textIndent1 + "✅ The minting has done successfully.");
  console.log("");

  console.log(textIndent1 + "🏁 Sending the transaction to the forked network ...");
  try {
    await ethers.provider.sendTransaction(txResponse.raw);
    console.log(textIndent1 + "✅ The transaction has been sent successfully!");
  } catch (e: any) {
    const errorData = e.data;
    console.log(textIndent1 + `❌ Transaction sending failed!`);
    console.log(textIndent2 + `👉 The exception message:`, e.message);
    console.log(textIndent2 + `👉 The error data:`, errorData);
    if (!!errorData && errorData.length > 2) {
      console.log(textIndent2 + "👉 The result of error data decoding:");
      console.log(await decodeErrorData(errorData, textIndent3 + " "));
    }
  }
}

console.log("STARTED")
console.log(rpcUrl)
console.log(txHash)
main();
console.log("FINISHED")
