// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;

// Uncomment this line to use console.log
import "hardhat/console.sol";

// Uniswap interface and library imports
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";
import "hardhat/console.sol";

contract FlashLoan {
     using SafeERC20 for IERC20;
//variables start:
//point1:
//all the variables are made constant using constant keyword
//because want to make the contract optimized
//making variable constant we can save gas. and we dont need to change these too

//point2:
//made all of them private. because dont need them to access publicly
//also making variable public takes more gas fees

//all the addresses are taken from binance smart chain explorer website: bsbscan.com
//as we taken in the token swap case
// Factory and Routing Addresses
    // Factory and Routing Addresses
    address private constant PANCAKE_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Token Addresses
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    uint256 private deadline = block.timestamp + 1 days;

    //taken from google
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
//variables end;;;


///
/////step3 in functions:
///
/////
    function checkResult(uint _repayAmount,uint _acquiredCoin) pure private returns(bool){
        console.log("The Amount to pay:",_repayAmount);
        console.log("The amount acquired after arbitrage:",_acquiredCoin);
        return _acquiredCoin>_repayAmount;
    }

//extra function
     // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }


///
/////step4 in functions:
///
/////
    function placeTrade(address _fromToken,address _toToken,uint _amountIn) private returns(uint){
        //fetchig the LP address
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            _fromToken,
            _toToken
        );

    //check if LP address has come correctly
    //checks if the variable pair is not equal to the Ethereum zero address (address(0)). 
    //The zero address in Ethereum is commonly used to represent an uninitialized or non-existent address.
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out
        //this array needed to pass arguments for the later functions
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

    //estimating or expected amount fetch. see the function. It is in:https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
        uint256 amountRequired = IUniswapV2Router01(PANCAKE_ROUTER)
            .getAmountsOut(_amountIn, path)[1];

    //Taking the actual amount
        uint256 amountReceived = IUniswapV2Router01(PANCAKE_ROUTER)
            .swapExactTokensForTokens(
                _amountIn, 
                amountRequired, 
                path,
                address(this),
                deadline 
            )[1];

    //now check if received amout is not zero. if zero this function revert, so the all the previous function revert
        require(amountReceived > 0, "Transaction Abort");
    //if non zero return the amount
        return amountReceived;
    }

///
/////step1 in functions:
///
// function initiateArbitrage(address _busdBorrow, uint _amount)external{
//parameters: the address of the token we want to borrow. and the amount want to borrow.
//can take any token according to our choice.
    function initateArbitrage(address _busdBorrow,uint _amount) external{
    //giving BUSD's unlimited approval to "PANCAKE_ROUTER"
    //doing from "SafeERC20 for IERC20" taken above
         IERC20(BUSD).safeApprove(address(PANCAKE_ROUTER),MAX_INT);
    //through this we are giving the "PANCAKE_ROUTER" authority that, it can spent unlimited "BUSD" token on behalf of me
    //because we will use flash loan. we dont want to do the authority giving thing manually again and again
    //similarly for: CROX, CAKE
         IERC20(CROX).safeApprove(address(PANCAKE_ROUTER),MAX_INT);
         IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER),MAX_INT);
         
//we are basically using BUSD, CROX, CAKE tokens. token address address has fetched of "those tokens contract"
//but it has come from following IERC20 so we are using its interface only

    //accessing liquidity pool. returns thee LP address
         address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
        //give me a LP that delas with BUSD and WBNB
        //helps in trading between them
            _busdBorrow,
            WBNB
         );

         
//the LP we fetched here, in it at the 0th index there is address of WBNB token
//and at the 1st index there is address of BUSD token

//checking if any pool exist with tokens or not
         require(pair!=address(0),"Pool does not exist");


 //the liquidity pool fethced, 
    //simply taking the address of the zeroth, and 1st tokens address of that pool
    //did just so that our contract do it automatically we do not need to check manually
         address token0 = IUniswapV2Pair(pair).token0();//WBNB
         address token1 = IUniswapV2Pair(pair).token1();//BUSD

//checking if the borrowed account= token0. no its not. So put amount0Out=0
         uint amount0Out = _busdBorrow==token0?_amount:0;
//checking if the borrowed account "_busdBorrow"= token1. yes, it is.So, put amount0Out=_amount
//transfered the amount we borrowed to "amount1Out"
         uint amount1Out = _busdBorrow==token1?_amount:0; //BUSD Amount
         
//by passing this to the interface below, we are telling that the amount we borrowed, we are going to use it in our flashloan
//in other words we are triggering the flashloan
//see: "https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps" here the "Triggering a Flash Swap" part
//forking from abve address pancake has built. need to see this repository: https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/PancakePair.sol
         bytes memory data = abi.encode(_busdBorrow,_amount,msg.sender);
         
         
//implementing "swap()" function of "IUniswapV2Pair" interface
//the "pair" parameter is implying the liquidity contract. that holds the tow tokens' addresses
//through those here the amount0Out, amount1Out are fethced and passed in swap() function
//this makes sure among "amount0Out" & "amount1Out" which is non-zero, 
//that qauntity of token in transfered in our contract address "addres(this)",
//see: "https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol"
// and the parameter "data" variable is defined above
         IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    
    //we are basically using pancakeswap. pair address or LP address has fetched from "panckae"
//but it has come from forking uniswapv2 so we are using its interface
    }



///
/////step2 in functions:
///
/////
//must give the name as it is.
//because it will be internally called by the swap function used in previous function
    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        // Ensure this request came from the contract
  //1st we will fetch the token0 & token1
//in the msg.sender here will be the adress of the liquidity pool. coz through that contract we calling our tonek contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        
//the trading part will happen here so. we will now use the previously fetched BUSD to do triangular arbitrage

        //taking the liquidity pool address of the token0, token1
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            token0,
            token1
        );
    //checking if this address matches with the called liquidity pool. just for verifying purpose. so that any wrong adress is not taken
        require(msg.sender == pair, "The sender needs to match the pair");
    //making sure the sender address is the contract adress. so that our contract is not called by someone else. for security pusppose
        require(_sender == address(this), "Sender should match the contract");

    //decoding the "data" we encoded in previous function
        (address busdBorrow, uint256 amount, address myAddress) = abi.decode(
            _data,
            (address, uint256, address)
        );
         //so, here we have got our borrowed BUSD, amount and account

    ///now need to calculate the fees
    //commonly used in decentralized exchanges (DEXs) and automated market makers (AMMs) like PancakeSwap to calculate the trading fee for a transaction.
    //3/997: This is a constant ratio often used to calculate fees in some DEXs.
    //The addition of 1 ensures that even very small trades have a minimum fee.
        // Calculate the amount to repay at the end
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 repayAmount = amount + fee;

        // DO ARBITRAGE
        // Assign loan amount
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;//came in the arguents. if amount0!=0 then that is the loanAmount, otherwise, amount1


        // Place Trades
        //triangular arbitrage:
        uint256 trade1Coin = placeTrade(BUSD, CROX, loanAmount);
          //similarly 2nd and 3rd
        //taking CROX using BUSD
        uint256 trade2Coin = placeTrade(CROX, CAKE, trade1Coin);//taking CAKE using CROX
        uint256 trade3Coin = placeTrade(CAKE, BUSD, trade2Coin);//taking BUSD using CAKE
     //the 3rd function placeTrade() called here. declared above


        // Check Profitability
        bool profCheck = checkResult(repayAmount, trade3Coin);
         // check the the condition of flashloan. if profit happened r not
        require(profCheck, "This Triangular Arbitrage is not profitable");
     //if these revert this function revert, as a result the previous function will also revert

     //if profit then:
        // Pay Myself
        IERC20(BUSD).transfer(myAddress, trade3Coin - repayAmount );//transfer the profit to myAccount usinf IERC20 tokens transfer function
        // Pay Loan Back
        IERC20(busdBorrow).transfer(pair, repayAmount);//pay back the borrowd amount to LP account
    }



}