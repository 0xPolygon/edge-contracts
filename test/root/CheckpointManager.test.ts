import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { randomBytes, hexlify, arrayify } from "ethers/lib/utils";
import {
  BLS,
  BN256G2,
  RootValidatorSet,
  CheckpointManager,
} from "../../typechain";

const DOMAIN = ethers.utils.hexlify(ethers.utils.randomBytes(32));

describe("CheckpointManager", () => {
  let bls: BLS,
    bn256G2: BN256G2,
    rootValidatorSet: RootValidatorSet,
    checkpointManager: CheckpointManager,
    submitCounter: number,
    validatorSetSize: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = await BN256G2.deploy();
    await bn256G2.deployed();

    const RootValidatorSet = await ethers.getContractFactory(
      "RootValidatorSet"
    );
    rootValidatorSet = await RootValidatorSet.deploy();
    await rootValidatorSet.deployed();

    const CheckpointManager = await ethers.getContractFactory(
      "CheckpointManager"
    );
    checkpointManager = await CheckpointManager.deploy();
    await checkpointManager.deployed();
  });

  it("Initialize and validate initialization", async () => {
    await checkpointManager.initialize(
      bls.address,
      bn256G2.address,
      rootValidatorSet.address,
      DOMAIN
    );
    expect(await checkpointManager.bls()).to.equal(bls.address);
    expect(await checkpointManager.bn256G2()).to.equal(bn256G2.address);
    expect(await checkpointManager.rootValidatorSet()).to.equal(
      rootValidatorSet.address
    );
    expect(await checkpointManager.domain()).to.equal(DOMAIN);
  });

  it("Submit with non-sequential id", async () => {
    submitCounter = 2;
    const checkPoint = {
      startBlock: 100,
      endBlock: 200,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    await expect(
      checkpointManager.submit(submitCounter, checkPoint, [DOMAIN, DOMAIN], [])
    ).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });

  it("Submit with invalid start block", async () => {
    submitCounter = 1;
    const checkPoint = {
      startBlock: 100,
      endBlock: 200,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    await expect(
      checkpointManager.submit(
        submitCounter,
        checkPoint,
        [
          ethers.utils.hexlify(ethers.utils.randomBytes(32)),
          ethers.utils.hexlify(ethers.utils.randomBytes(32)),
        ],
        []
      )
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });

  it("Submit with empty checkpoint", async () => {
    submitCounter = 1;
    const checkPoint = {
      startBlock: 1,
      endBlock: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    await expect(
      checkpointManager.submit(
        submitCounter,
        checkPoint,
        [
          ethers.utils.hexlify(ethers.utils.randomBytes(32)),
          ethers.utils.hexlify(ethers.utils.randomBytes(32)),
        ],
        []
      )
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });
});
