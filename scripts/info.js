const { ethers } = require("ethers")
const Web3 = require('web3')
const APM = require('@aragon/apm')
const namehash = require('eth-ens-namehash').hash
const web3 = new Web3(process.env.RPC_NODE)
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY)
                    .connect(new ethers.providers.JsonRpcProvider(process.env.RPC_NODE))
const KernelABI = require("../build/contracts/Kernel.json").abi
const ACLABI = require("../build/contracts/ACL.json").abi
const apm = APM(web3, {ensRegistryAddress: process.env.ARAGON_ENS})
const daoAddress = process.env.DAO

async function main(){
  // return
  const dao = new ethers.Contract(daoAddress, KernelABI, wallet);
  const APP_MANAGER_ROLE = await dao.APP_MANAGER_ROLE()
  const aclAddress = await dao.acl()
  const acl = new ethers.Contract(aclAddress, ACLABI, wallet);
  const allowed = await acl.hasPermission(wallet.address, daoAddress, APP_MANAGER_ROLE)
  console.log(allowed)
}
main()

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
