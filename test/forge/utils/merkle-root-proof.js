// Get Merkle Root and Merkle Proof for 32 leaves and index
// Input: ABI-encoded bytes32[32] leaves and uint256 index
// Output: ABI-encoded bytes32 root and bytes32[] proof

const { ethers } = require("ethers");
const { MerkleTree } = require("merkletreejs");

const input = process.argv[2];
const data = ethers.utils.defaultAbiCoder.decode(["bytes32[32]", "uint256"], input);
const [leaves, index] = data;

const tree = new MerkleTree(leaves, ethers.utils.keccak256);
const root = tree.getHexRoot();
const proof = tree.getHexProof(leaves[index]);

const output = ethers.utils.defaultAbiCoder.encode(["bytes32", "bytes32[]"], [root, proof]);
console.log(output);
