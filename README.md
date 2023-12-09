# Demonstrating Flashloan Using Hardhat. 
This project demonstrates a basic Flashloan execution. It comes with a sample contract, a test for that contract. Executing This FlashLoan Using PancakeSwap and Forking BNB Smart Chain Mainnet.
-- First set up the environment with harthat
-- Then created the solidity smartcontract for implementing FLASHLOAN
-- The Libraries and Interfaces of PancakeSwap Smartcontract
-- Then with the help of hardhat tested the flashloan. 
-- As we can not perform arbitrage without the help of the Instance of the BNB Smart Chain Mainnet so we performed the testing Forking the BNB Smart Chain Mainnet
-- We also had to impersonate or clone a dummuy of a real account that holds a lot of BUSD
-- Then our contract will borrow some amount of BUSD from that account and will perform arbitrage(Triangular Arbitrage)

Try running some of the following tasks:
```shell
#in the root folder
npm install --force
npx hardhat test
```
