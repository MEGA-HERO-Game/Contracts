// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256} = require('ethereumjs-util')
const {BigNumber} = require("ethers");

describe("OperatorProxy V1", function () {

  let owner;
  let operator;
  let minter;
  let operatorPrivate='0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';

  let hardhatDiamondCard;
  let hardhatMPNFT;
  let oldMPNFT;
  let hardhatOperatorProxy;
  let usdt;
  let ibox;
  let invitationSigner;
  let withdrawSigner;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, operator, minter, ...addrs] = await ethers.getSigners();

    invitationSigner = ibox = withdrawSigner = oldMPNFT = usdt = operator;

    //  deploy the diamond card token
    let DiamondCard = await ethers.getContractFactory("DiamondCard")
    hardhatDiamondCard = await DiamondCard.deploy([]);
    await  hardhatDiamondCard.connect(owner).setOperator(operator.address);

    //  deploy the mp nft;
    let MPNFT = await ethers.getContractFactory("MP");
    hardhatMPNFT = await MPNFT.deploy([]);

    //  deploy operator proxy contract
    let OperatorProxy = await ethers.getContractFactory("Operator");
    hardhatOperatorProxy = await OperatorProxy.deploy(
        hardhatDiamondCard.address,
        hardhatMPNFT.address,
        oldMPNFT.address,
        usdt.address,
        invitationSigner.address,
        ibox.address,
        withdrawSigner.address);

    await hardhatOperatorProxy.connect(owner).setLimit(10, 10);
    // set Operator Proxy contract to the operator
    await  hardhatMPNFT.connect(owner).setOperator(hardhatOperatorProxy.address);

  });


  describe("Withdraw", function () {
    it("Should withdraw is ok", async function () {
      // Withdraw(mint nft and diamond card)
      let _mpIds = [1,2];
      let _diaIds = [];
      let _diaAmounts = [];
      let _nonce = 0;

      // withdraw(
      // address _user,
      // uint256[] calldata _mpIds,
      // uint256[] calldata _diaIds,
      // uint256[] calldata _diaAmounts,
      // uint256 _nonce,
      // uint8 _v,
      // bytes32 _r,
      // bytes32 _s
      // )

      //  cal sig
      // abi.encodePacked(_user, _mpIds, _diaIds, _diaAmounts, _nonce)
      let withdrawHash = await ethers.utils.solidityKeccak256(["uint160","uint256[]", "uint256[]", "uint256[]", "uint256"], [minter.address, _mpIds, _diaIds, _diaAmounts, _nonce]);
      let withdrawHashBytes = ethers.utils.arrayify(withdrawHash);
      let signingKey = new ethers.utils.SigningKey(operatorPrivate);
      let signature = signingKey.signDigest(withdrawHashBytes);

      //  withdraw
      await  hardhatOperatorProxy.connect(operator).withdraw(minter.address, _mpIds, _diaIds, _diaAmounts, _nonce, signature.v, signature.r, signature.s);
      let balance = await hardhatMPNFT.balanceOf(minter.address);
      expect(balance).to.equal(2);
      console.log("\t Mint and burn test done");
    });

  });

});
