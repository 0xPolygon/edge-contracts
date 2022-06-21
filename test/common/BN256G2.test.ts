import { assert } from "chai";
import { randHex, randFs, to32Hex } from "../../ts/utils";
import * as mcl from "../../ts/mcl";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { randomBytes, hexlify, arrayify } from "ethers/lib/utils";
import { expandMsg, hashToField } from "../../ts/hashToField";
import { BN256G2 } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("BN256G2", async () => {
  let bn256G2: BN256G2;
  before(async function () {
    await mcl.init();
    const bn256G2Factory = await ethers.getContractFactory("BN256G2");
    bn256G2 = await bn256G2Factory.deploy();
    await bn256G2.deployTransaction.wait();
  });
  it("Addition on G2 (1 point)", async function () {
    const pks = [];
    const rawPks: mcl.PublicKey[] = [];
    for (let i = 0; i <= 1; i++) {
      let { pubkey, secret } = mcl.newKeyPair();
      rawPks.push(pubkey);
      pks.push(mcl.g2ToHex(pubkey));
    }
    const bignumberPk = mcl
      .g2ToHex(mcl.aggregatePks(rawPks))
      .map((elem) => BigNumber.from(elem));
    assert.deepEqual(
      await bn256G2.ecTwistAdd(
        pks[0][0],
        pks[0][1],
        pks[0][2],
        pks[0][3],
        pks[1][0],
        pks[1][1],
        pks[1][2],
        pks[1][3]
      ),
      bignumberPk
    );
  });
  it("Addition on G2 (50 points)", async function () {
    const pks = [];
    const rawPks: mcl.PublicKey[] = [];
    for (let i = 0; i < 50; i++) {
      let { pubkey, secret } = mcl.newKeyPair();
      rawPks.push(pubkey);
      pks.push(mcl.g2ToHex(pubkey));
    }
    const bignumberPk = mcl
      .g2ToHex(mcl.aggregatePks(rawPks))
      .map((elem) => BigNumber.from(elem));
    let aggPk: mcl.PublicKey = pks[0];
    for (let i = 1; i < 50; i++) {
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
  it("Multiplication on G2", async function () {
    const pk = [
      "0x282d10b63d152703cd547a3527fa8eb55e3c8a247db0b44234c15cb7a3845322",
      "0x2c994d1ef1c44b111eb3ebd6e6cc50ed793926d3abb322cb78bf5417330913fd",
      "0x195c27dcaf8ed361e07439175d711076f5abcd20354c9e55eabae89d52be6343",
      "0x0c1ed23003ae31a537e5819a746f0e6f5c7026393ade17593effb8f7c1113513",
    ];
    const scalar = 99999;
    const bigNumberG2 = [
      BigNumber.from(
        "1561028406349898675044359631948161218779534356513732350000699820549174457112"
      ),
      BigNumber.from(
        "17937178375596143385147795410243536400147485650141631325646673982498737574238"
      ),
      BigNumber.from(
        "2435020648792258737161168180465958517808164998154609791860646996217520625801"
      ),
      BigNumber.from(
        "11366340409469806058093028668983112869367947562240910240143227593721927519454"
      ),
    ];
    assert.deepEqual(
      await bn256G2.ecTwistMul(scalar, pk[0], pk[1], pk[2], pk[3]),
      bigNumberG2
    );
  });
});
