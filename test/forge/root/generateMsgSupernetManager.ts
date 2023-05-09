import { ethers } from "ethers";
import * as mcl from "../../../ts/mcl";
const signerAddress = process.argv[2];
const contractAddress = process.argv[3];

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["CUSTOM_SUPERNET_MANAGER"]));
const CHAIN_ID = 31337;

async function generateRegistrationSignature(signerAddress: string, contractAddress: string) {
  await mcl.init();
  const { pubkey, secret } = mcl.newKeyPair();
  const parsedPubkey = mcl.g2ToHex(pubkey);
  const { signature } = mcl.signSupernetMessage(DOMAIN, CHAIN_ID, signerAddress, contractAddress, secret);

  const parsedSignature = mcl.g1ToHex(signature);

  const output = ethers.utils.defaultAbiCoder.encode(["uint256[2]", "uint256[4]"], [parsedSignature, parsedPubkey]);

  console.log(output);
}

generateRegistrationSignature(signerAddress, contractAddress);
