// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256} = require('ethereumjs-util')
const {BigNumber} = require("ethers");

describe("MetaWorld V1", function () {

  let MetaWorld;
  let hardhatMetaWorld;
  let owner;    // 合约部署方
  let operator; // 合约后台操作方
  let minter;
  let addrs;
  let withdrawSigner = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8";
  let withdrawSingerPrivate='0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';

  beforeEach(async function () {
    // Construction parameters
    const params = [
      withdrawSigner,
    ];

    MetaWorld = await ethers.getContractFactory("MetaWorld");
    [owner, operator, minter, ...addrs] = await ethers.getSigners();

    hardhatMetaWorld = await MetaWorld.deploy(withdrawSigner);
    await hardhatMetaWorld.deployed();
    await  hardhatMetaWorld.connect(owner).setOperator(operator.address);

  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      expect(await hardhatMetaWorld.owner()).to.equal(owner.address);
    });
  });


  describe("MintBurn", function () {
    it("Should mint and burn is ok", async function () {
      // mint1
      let id = [1,2];

      // set operator
      await  hardhatMetaWorld.connect(owner).setOperator(operator.address);
      let contractOperator = await hardhatMetaWorld.operator();
      expect(contractOperator).to.equal(operator.address);

      // operator mint nft id 1 and id 2 to minter
      await  hardhatMetaWorld.connect(operator).operatorMint(minter.address, id);
      let balance = await hardhatMetaWorld.balanceOf(minter.address);
      expect(balance).to.equal(2);

      // aprove the nft from minter to operator
      await hardhatMetaWorld.connect(minter).approve(operator.address, id[0])
      let isSelfOwner =  operator.address == minter.address
      let isApproved =  await hardhatMetaWorld.getApproved(id[0]) == operator.address
      let isApprovedAll = await hardhatMetaWorld.isApprovedForAll(minter.address, operator.address)
      isApproved = isApproved | isSelfOwner | isApprovedAll
      expect(isApproved).to.equal(1);

      // burn by operator
      await hardhatMetaWorld.connect(operator).burn(id[0])

      // balance is must 1
      balance = await hardhatMetaWorld.balanceOf(minter.address);
      expect(balance).to.equal(1);

      console.log("\t Mint and burn test done");
    });

  });

  describe("Withdraw", function () {
    it("Should withdraw is ok", async function () {
      // Withdraw(mint nft and diamond card)
      let _mpIds = [1,2];
      let _nonce = 0;

      // withdraw(
      // address _user,
      // uint256[] calldata _mpIds,
      // uint256 _nonce,
      // uint8 _v,
      // bytes32 _r,
      // bytes32 _s
      // )

      //  cal sig
      // abi.encodePacked(_user, _mpIds, _nonce)
      let withdrawHash = await ethers.utils.solidityKeccak256(["uint160","uint256[]", "uint256"], [minter.address, _mpIds, _nonce]);
      let withdrawHashBytes = ethers.utils.arrayify(withdrawHash);
      let signingKey = new ethers.utils.SigningKey(withdrawSingerPrivate);
      let signature = signingKey.signDigest(withdrawHashBytes);

      //  withdraw
      await  hardhatMetaWorld.connect(operator).withdraw(minter.address, _mpIds, _nonce, signature.v, signature.r, signature.s);
      let balance = await hardhatMetaWorld.balanceOf(minter.address);
      expect(balance).to.equal(2);
      console.log("\t Mint and burn test done");
    });

  });


});
