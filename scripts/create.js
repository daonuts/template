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
  const challengeAddress = await apm.getLatestVersionContract("challenge-app.open.aragonpm.eth")
  console.log("challengeAddress", challengeAddress)
  const subscribeAddress = await apm.getLatestVersionContract("subscribe-app.open.aragonpm.eth")
  console.log("subscribeAddress", subscribeAddress)
  const tippingAddress = await apm.getLatestVersionContract("tipping-app.open.aragonpm.eth")
  console.log("tippingAddress", tippingAddress)
  // return
  const template = new ethers.Contract(templateAddress, TemplateABI, wallet);
  const txContribToken = await template.createToken("Contrib", 18, "CONTRIB", false)
  await txContribToken.wait()
  console.log("txContribToken")
  const txCurrencyToken = await template.createToken("Currency", 18, "CURRENCY", true)
  await txCurrencyToken.wait()
  console.log("txCurrencyToken")
  // const txDao = await template.newInstance("Contrib", "Currency", process.env.APP_INSTALLER)
  const txDao = await template.newInstance("Contrib", "Currency")
  console.log("txDao")
  const daoBlock = await txDao.wait()
  console.log("dao transactionHash", daoBlock.transactionHash)

  let templateWeb3 = new web3.eth.Contract(TemplateABI, templateAddress)
  const dao = await templateWeb3.getPastEvents('DeployDao', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.transactionHash===daoBlock.transactionHash)[0].returnValues.dao)
  console.log(`dao: ${dao}`)

  // await templateWeb3.getPastEvents('Debug', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
  //   .then(console.log)
  //
  await templateWeb3.getPastEvents('DebugBool', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(console.log)

  // await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
  //   .then(console.log)

  const votingAppId = namehash("voting.aragonpm.eth")
  const voting = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===votingAppId)[0].returnValues.appProxy)
  console.log(`voting: ${voting}`)

  const tokenManagerAppId = namehash("token-manager.aragonpm.eth")
  // take first (1) from filtered array because the currencyManager is the second token manager installed
  const tokenManagers = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===tokenManagerAppId).map(e=>e.returnValues.appProxy))

  console.log(`tokenManagers: ${tokenManagers}`)
  //
  // const txTemplateApps = await template.installApps(dao, voting, tokenManagers[0], tokenManagers[1])
  // await txTemplateApps.wait()

}
main()

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
