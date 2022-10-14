import { ethers } from "ethers";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

async function generateMsg() {
  await mcl.init();
  const message = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator"));
  const { pubkey, secret } = mcl.newKeyPair();
  const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);

  const parsedPubkey = mcl.g2ToHex(pubkey);
  const parsedSignature = mcl.g1ToHex(signature);

  const messagePointForInit = mcl.g1ToHex(
    mcl.hashToPoint(ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator")), DOMAIN)
  );

  const output = ethers.utils.defaultAbiCoder.encode(
    ["uint256[2]", "uint256[2]", "uint256[4]"],
    [messagePointForInit, parsedSignature, parsedPubkey]
  );

  console.log(output);
}

generateMsg();
