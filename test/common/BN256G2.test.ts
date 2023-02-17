import { assert } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import * as mcl from "../../ts/mcl";
import { BN256G2 } from "../../typechain-types";

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

describe("BN256G2", async () => {
  let bn256G2: BN256G2;
  before(async function () {
    await mcl.init();
    const bn256G2Factory = await ethers.getContractFactory("BN256G2");
    bn256G2 = (await bn256G2Factory.deploy()) as BN256G2;
    await bn256G2.deployTransaction.wait();
  });
  it("Addition on G2 (1 point)", async function () {
    const pks = [];
    const rawPks: mcl.PublicKey[] = [];
    for (let i = 0; i <= 1; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      rawPks.push(pubkey);
      pks.push(mcl.g2ToHex(pubkey));
    }
    const bignumberPk = mcl.g2ToHex(mcl.aggregatePks(rawPks)).map((elem) => BigNumber.from(elem));
    assert.deepEqual(
      await bn256G2.ecTwistAdd(pks[0][0], pks[0][1], pks[0][2], pks[0][3], pks[1][0], pks[1][1], pks[1][2], pks[1][3]),
      bignumberPk
    );
  });
  it("Addition on G2 (10 points)", async function () {
    const pks = [];
    const rawPks: mcl.PublicKey[] = [];
    for (let i = 0; i < 10; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      rawPks.push(pubkey);
      pks.push(mcl.g2ToHex(pubkey));
    }
    const bignumberPk = mcl.g2ToHex(mcl.aggregatePks(rawPks)).map((elem) => BigNumber.from(elem));
    let aggPk: mcl.PublicKey = pks[0];
    for (let i = 1; i < 10; i++) {
      aggPk = await bn256G2.ecTwistAdd(
        aggPk[0],
        aggPk[1],
        aggPk[2],
        aggPk[3],
        pks[i][0],
        pks[i][1],
        pks[i][2],
        pks[i][3]
      );
    }
    assert.deepEqual(aggPk, bignumberPk);
  });
  it("Multiplication on G2 (10 points)", async function () {
    for (let i = 0; i < 10; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      const pk = mcl.g2ToHex(pubkey);
      const scalar = Math.floor(Math.random() * (9999 - 1) + 1); // pick a random number from 1 - 9999
      const pubkeyMultiplied = mcl.mulG2FrInt(pubkey, scalar);
      const bigNumberG2 = mcl.g2ToHex(pubkeyMultiplied).map((elem) => BigNumber.from(elem));
      assert.deepEqual(await bn256G2.ecTwistMul(scalar, pk[0], pk[1], pk[2], pk[3]), bigNumberG2);
    }
  });
});
