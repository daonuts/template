const { ethers } = require("ethers")
const Web3 = require('web3')
const APM = require('@aragon/apm')
const namehash = require('eth-ens-namehash').hash
const web3 = new Web3(process.env.RPC_NODE)
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY)
                    .connect(new ethers.providers.JsonRpcProvider(process.env.RPC_NODE))
const TemplateABI = require("../build/contracts/Template.json").abi
const apm = APM(web3, {ensRegistryAddress: process.env.ARAGON_ENS})

async function main(){
  const templateAddress = await apm.getLatestVersionContract("daonuts-template1.open.aragonpm.eth")
  console.log("templateAddress", templateAddress)
  const templateAppsAddress = await apm.getLatestVersionContract("daonuts-template1-apps.open.aragonpm.eth")
  console.log("templateAppsAddress", templateAppsAddress)
  const airdropDuoAddress = await apm.getLatestVersionContract("airdrop-duo-app.open.aragonpm.eth")
  console.log("airdropDuoAddress", airdropDuoAddress)
  const cappedVotingAddress = await apm.getLatestVersionContract("capped-voting-app.open.aragonpm.eth")
  console.log("cappedVotingAddress", cappedVotingAddress)
  const challengeAddress = await apm.getLatestVersionContract("challenge-app.open.aragonpm.eth")
  console.log("challengeAddress", challengeAddress)
  const harbergerAddress = await apm.getLatestVersionContract("harberger-app.open.aragonpm.eth")
  console.log("harbergerAddress", harbergerAddress)
  const subscribeAddress = await apm.getLatestVersionContract("subscribe-app.open.aragonpm.eth")
  console.log("subscribeAddress", subscribeAddress)
  const tippingAddress = await apm.getLatestVersionContract("tipping-app.open.aragonpm.eth")
  console.log("tippingAddress", tippingAddress)
  // return
  const template = new ethers.Contract(templateAddress, TemplateABI, wallet);
  const txDao = await template.newInstance(process.env.CONTRIB_NAME, process.env.CONTRIB_SYMBOL, process.env.CURRENCY_NAME, process.env.CURRENCY_SYMBOL)
  console.log("txDao")
  const daoBlock = await txDao.wait()
  console.log("dao transactionHash", daoBlock.transactionHash)

  let templateWeb3 = new web3.eth.Contract(TemplateABI, templateAddress)
  const dao = await templateWeb3.getPastEvents('DeployDao', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.transactionHash===daoBlock.transactionHash)[0].returnValues.dao)
  console.log(`dao: ${dao}`)

  const tokenManagerAppId = namehash("token-manager.aragonpm.eth")
  const tokenManagers = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===tokenManagerAppId).map(e=>e.returnValues.appProxy))

  console.log(`tokenManagers: ${tokenManagers}`)

  const txSetup = await template.setup(dao, ...tokenManagers, wallet.address, process.env.FIRST_AIRDROP_ROOT, process.env.FIRST_AIRDROP_DATA_URI)
  console.log("txSetup")
  const setupBlock = await txSetup.wait()
  console.log("setup transactionHash", setupBlock.transactionHash)

  await templateWeb3.getPastEvents('DEBUG', {fromBlock: setupBlock.blockNumber, toBlock: setupBlock.blockNumber})
    .then(console.log)

}
main()

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
