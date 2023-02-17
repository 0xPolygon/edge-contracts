import { assert } from "chai";
import { hexlify, randomBytes } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { expandMsg, hashToField } from "../../ts/hashToField";
import * as mcl from "../../ts/mcl";
import { randFs, randHex, to32Hex } from "../../ts/utils";
import { BLS } from "../../typechain-types";

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

const g2PointOnIncorrectSubgroup: mcl.solG2 = [
  "0x1ef4bf0d452e71f1fb23948695fa0a87a10f3d9dce9d32fadb94711f22566fb5",
  "0x237536b6a72ac2e447e7b34a684a81d8e63929a4d670ce1541730a7e03c3f0f2",
  "0x0a63f14620a64dd39394b6e89c48679d3f2ce0c46a1ef052ee3df0bd66c198cb",
  "0x0fe4020ece1b2849af46d308e9f201ac58230a45e124997f52c65d28fe3cf8f1",
];

describe("BLS", async () => {
  let bls: BLS;
  before(async function () {
    await mcl.init();
    const BLS = await ethers.getContractFactory("BLS");
    bls = (await BLS.deploy()) as BLS;
  });
  it("map to point", async function () {
    for (let i = 0; i < 100; i++) {
      const e = randFs();
      const [expectX, expectY] = mcl.g1ToHex(mcl.mapToPoint(e));
      const [actualX, actualY] = await bls.mapToPoint(e);
      assert.equal(to32Hex(actualX), expectX, "e " + e);
      assert.equal(to32Hex(actualY), expectY, "e " + e);
    }
  });
  it("expand message to 96", async function () {
    for (let i = 0; i < 100; i++) {
      const msg = randomBytes(i);
      const expected = expandMsg(DOMAIN, msg, 96);
      const result = await bls.expandMsgTo96(DOMAIN, msg);
      assert.equal(result, hexlify(expected));
    }
  });
  it("hash to field", async function () {
    for (let i = 0; i < 100; i++) {
      const msg = randomBytes(i);
      const [expectX, expectY] = hashToField(DOMAIN, msg, 2);
      const [actualX, actualY] = await bls.hashToField(DOMAIN, msg);
      assert.equal(actualX.toHexString(), expectX.toHexString());
      assert.equal(actualY.toHexString(), expectY.toHexString());
    }
  });
  it("hash to point", async function () {
    for (let i = 0; i < 100; i++) {
      const msg = randHex(i);
      const [expectX, expectY] = mcl.g1ToHex(mcl.hashToPoint(msg, DOMAIN));
      const [actualX, actualY] = await bls.hashToPoint(DOMAIN, msg);
      assert.equal(to32Hex(actualX), expectX);
      assert.equal(to32Hex(actualY), expectY);
    }
  });
  it("verify aggregated signature", async function () {
    const n = 10;
    const messages = [];
    const pubkeys = [];
    const signatures = [];
    for (let i = 0; i < n; i++) {
      const message = randHex(12);
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      messages.push(mcl.g1ToHex(messagePoint));
      pubkeys.push(mcl.g2ToHex(pubkey));
      signatures.push(signature);
      const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
      const res = await bls.verifyMultiple(aggSignature, pubkeys, messages);
      assert.isTrue(res[0]);
      assert.isTrue(res[1]);
    }
  });
  it("verify aggregated signature, same message", async function () {
    const n = 10;
    const message = hexlify(randomBytes(12));
    const pubkeys = [];
    const signatures = [];
    for (let i = 0; i < n; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      pubkeys.push(mcl.g2ToHex(pubkey));
      signatures.push(signature);
      const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
      const res = await bls.verifyMultipleSameMsg(aggSignature, pubkeys, mcl.g1ToHex(mcl.hashToPoint(message, DOMAIN)));
      assert.isTrue(res[0]);
      assert.isTrue(res[1]);
    }
  });
  it("verify aggregated signature, aggregated public key", async function () {
    const n = 10;
    const message = hexlify(randomBytes(12));
    const pubkeys = [];
    const signatures = [];
    for (let i = 0; i < n; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      pubkeys.push(pubkey);
      signatures.push(signature);
      const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
      const aggPublicKey = mcl.g2ToHex(mcl.aggregatePks(pubkeys));
      const res = await bls.verifySingle(aggSignature, aggPublicKey, mcl.g1ToHex(mcl.hashToPoint(message, DOMAIN)));
      assert.isTrue(res[0]);
      assert.isTrue(res[1]);
    }
  });
  it("verify aggregated signature: fail bad signature", async function () {
    const n = 10;
    const messages = [];
    const pubkeys = [];
    const signatures = [];
    for (let i = 0; i < n; i++) {
      const message = randHex(12);
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      messages.push(mcl.g1ToHex(messagePoint));
      pubkeys.push(mcl.g2ToHex(pubkey));
      if (i != 0) {
        signatures.push(signature);
      }
    }
    const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
    const res = await bls.verifyMultiple(aggSignature, pubkeys, messages);
    assert.isFalse(res[0]);
    assert.isTrue(res[1]);
  });
  it("verify aggregated signature: fail signature is not on curve", async function () {
    const n = 10;
    const messages = [];
    const pubkeys = [];
    for (let i = 0; i < n; i++) {
      const message = randHex(12);
      const { pubkey, secret } = mcl.newKeyPair();
      const { messagePoint } = mcl.sign(message, secret, DOMAIN);
      messages.push(mcl.g1ToHex(messagePoint));
      pubkeys.push(mcl.g2ToHex(pubkey));
    }
    const aggSignature: mcl.solG1 = [100, 100];
    let res = await bls.verifyMultiple(aggSignature, pubkeys, messages);
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("verify aggregated signature: fail pubkey is not on curve", async function () {
    const n = 10;
    const messages = [];
    const pubkeys: mcl.solG2[] = [];
    const signatures = [];
    for (let i = 0; i < n; i++) {
      const message = randHex(12);
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      messages.push(mcl.g1ToHex(messagePoint));
      if (i == 0) {
        pubkeys.push([3, 3, 3, 3]);
      } else {
        pubkeys.push(mcl.g2ToHex(pubkey));
      }
      signatures.push(signature);
    }
    const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
    const res = await bls.verifyMultiple(aggSignature, pubkeys, messages);
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("verify aggregated signature: fail pubkey is not on correct subgroup", async function () {
    const n = 10;
    const messages = [];
    const pubkeys = [];
    const signatures = [];

    for (let i = 0; i < n; i++) {
      const message = randHex(12);
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      messages.push(mcl.g1ToHex(messagePoint));
      if (i == 0) {
        pubkeys.push(g2PointOnIncorrectSubgroup);
        assert.isTrue(await bls.isOnCurveG2(pubkeys[i]));
      } else {
        pubkeys.push(mcl.g2ToHex(pubkey));
      }
      signatures.push(signature);
    }
    const aggSignature = mcl.g1ToHex(mcl.aggregateRaw(signatures));
    let res = await bls.verifyMultiple(aggSignature, pubkeys, messages);
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("verify single signature", async function () {
    const message = randHex(12);
    const { pubkey, secret } = mcl.newKeyPair();
    const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
    let res = await bls.verifySingle(mcl.g1ToHex(signature), mcl.g2ToHex(pubkey), mcl.g1ToHex(messagePoint));
    assert.isTrue(res[0]);
    assert.isTrue(res[1]);
  });
  it("verify single signature: fail bad signature", async function () {
    const message = randHex(12);
    const { pubkey } = mcl.newKeyPair();
    const { secret } = mcl.newKeyPair();
    const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
    let res = await bls.verifySingle(mcl.g1ToHex(signature), mcl.g2ToHex(pubkey), mcl.g1ToHex(messagePoint));
    assert.isFalse(res[0]);
    assert.isTrue(res[1]);
  });
  it("verify single signature: fail pubkey is not on curve", async function () {
    const message = randHex(12);
    const { secret } = mcl.newKeyPair();
    const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
    const pubkey: mcl.solG2 = [3, 3, 3, 3];
    let res = await bls.verifySingle(mcl.g1ToHex(signature), pubkey, mcl.g1ToHex(messagePoint));
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("verify single signature: fail signature is not on curve", async function () {
    const message = randHex(12);
    const { pubkey, secret } = mcl.newKeyPair();
    const { messagePoint } = mcl.sign(message, secret, DOMAIN);
    const signature: mcl.solG1 = [3, 3];
    let res = await bls.verifySingle(signature, mcl.g2ToHex(pubkey), mcl.g1ToHex(messagePoint));
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("verify single signature: fail pubkey is not on correct subgroup", async function () {
    const message = randHex(12);
    const { secret } = mcl.newKeyPair();
    const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
    const pubkey = g2PointOnIncorrectSubgroup;
    assert.isTrue(await bls.isOnCurveG2(pubkey));
    let res = await bls.verifySingle(mcl.g1ToHex(signature), pubkey, mcl.g1ToHex(messagePoint));
    assert.isFalse(res[0]);
    assert.isFalse(res[1]);
  });
  it("is on curve g1", async function () {
    for (let i = 0; i < 20; i++) {
      const point = mcl.randG1();
      let isOnCurve = await bls.isOnCurveG1(point);
      assert.isTrue(isOnCurve);
    }
    for (let i = 0; i < 20; i++) {
      const point: mcl.solG1 = [randomBytes(31), randomBytes(31)];
      const isOnCurve = await bls.isOnCurveG1(point);
      assert.isFalse(isOnCurve);
    }
  });
  it("is on curve g2", async function () {
    for (let i = 0; i < 20; i++) {
      const point = mcl.randG2();
      let isOnCurve = await bls.isOnCurveG2(point);
      assert.isTrue(isOnCurve);
    }
    for (let i = 0; i < 20; i++) {
      const point: mcl.solG2 = [randomBytes(31), randomBytes(31), randomBytes(31), randomBytes(31)];
      const isOnCurve = await bls.isOnCurveG2(point);
      assert.isFalse(isOnCurve);
    }
  });
});
