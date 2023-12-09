const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { fundContract } = require("../utils/utilities");
//this is imported and used here to perform the impersonating of a real busd holder's account
//as we are performing the test by forking the real network. 
//Means, taken the instance of the real BNB chain. Otherwise we will not be able to perform the arbitrage.
// now as we taken the copy of a real network. Also need a dummuy of a real account that holds a lot of BUSD
// then our contract will borrow some amount of BUSD from that account

const {
  abi,
} = require("../artifacts/contracts/interfaces/IERC20.sol/IERC20.json");

const provider = waffle.provider;

describe("FlashLoan Contract", () => {
  let FLASHLOAN,
    BORROW_AMOUNT,
    initialFundingHuman,
    FUND_AMOUNT,
    txArbitrage;


  const DECIMALS = 18;

  const BUSD_WHALE = "0xf977814e90da44bfa03b6295a0616a897441acec";
  const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
  const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
  const CROX = "0x2c094F5A7D1146BB93850f629501eB749f6Ed491";


  const busdInstance = new ethers.Contract(BUSD, abi, provider);

  // console.log("busd isnstance:",busdInstance)

  beforeEach(async () => {

    // Ensure that the WHALE has a balance
    const whale_balance = await provider.getBalance(BUSD_WHALE);
    expect(whale_balance).not.equal("0");

    // Deploy smart contract
    const FlashLoan = await ethers.getContractFactory("FlashLoan");
    FLASHLOAN = await FlashLoan.deploy();
    await FLASHLOAN.deployed();

    const borrowAmountHuman = "2";
    BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmountHuman, DECIMALS);

    initialFundingHuman = "200";
    FUND_AMOUNT = ethers.utils.parseUnits(initialFundingHuman, DECIMALS);

    // Fund our Contract - FOR TESTING ONLY
    await fundContract(
      busdInstance,
      BUSD_WHALE,
      FLASHLOAN.address,
      initialFundingHuman
    );
  });

  describe("Arbitrage Execution", () => {
    it("ensures the contract is funded", async () => {
      const flashLoanBalance = await FLASHLOAN.getBalanceOfToken(
        BUSD
      );

      const flashSwapBalanceHuman = ethers.utils.formatUnits(
        flashLoanBalance,
        DECIMALS
      );
      expect(Number(flashSwapBalanceHuman)).equal(Number(initialFundingHuman));
    });

    it("executes the arbitrage", async () => {

      const contractBalanceBUSDbefore = await FLASHLOAN.getBalanceOfToken(BUSD);
      const formattedBalBUSDbefore = Number(
        ethers.utils.formatUnits(contractBalanceBUSDbefore, 0)
      );
      console.log("Balance of BUSD before arbitrage: " + formattedBalBUSDbefore);

      txArbitrage = await FLASHLOAN.initateArbitrage(
        BUSD,
        BORROW_AMOUNT
      );

      assert(txArbitrage);

      // Print balances after
      const contractBalanceBUSD = await FLASHLOAN.getBalanceOfToken(BUSD);
      const formattedBalBUSD = Number(
        ethers.utils.formatUnits(contractBalanceBUSD, 0)
      );
      console.log("Balance of BUSD: " + formattedBalBUSD);

      const contractBalanceCROX = await FLASHLOAN.getBalanceOfToken(CROX);
      const formattedBalCROX = Number(
        ethers.utils.formatUnits(contractBalanceCROX, DECIMALS)
      );
      console.log("Balance of CROX: " + formattedBalCROX);

      const contractBalanceCAKE = await FLASHLOAN.getBalanceOfToken(CAKE);
      const formattedBalCAKE = Number(
        ethers.utils.formatUnits(contractBalanceCAKE, DECIMALS)
      );
      console.log("Balance of CAKE: " + formattedBalCAKE);
    });
  });
});