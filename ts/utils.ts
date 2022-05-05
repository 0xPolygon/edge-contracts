import { ethers, BigNumber } from "ethers";
import { randomBytes, hexlify, hexZeroPad } from "ethers/lib/utils";
import { FIELD_ORDER } from "./hashToField";

export function randHex(n: number): string {
  return hexlify(randomBytes(n));
}

export function to32Hex(n: BigNumber): string {
  return hexZeroPad(n.toHexString(), 32);
}

export function randFs(): BigNumber {
  const r = BigNumber.from(randomBytes(32));
  return r.mod(FIELD_ORDER);
}
