const { ethers } = require("ethers")
const Web3 = require('web3')
const APM = require('@aragon/apm')
const namehash = require('eth-ens-namehash').hash
const aragonENS = "0x5f6f7e8cc7346a11ca2def8f827b7a0b612c56a1"
const RPC_NODE = "http://localhost:8545"
const web3 = new Web3(RPC_NODE)
const wallet = new ethers.Wallet("a8a54b2d8197bc0b19bb8a084031be71835580a01e70a45a13babd16c9bc1563")
                    .connect(new ethers.providers.JsonRpcProvider(RPC_NODE))
const TemplateABI = require("../build/contracts/Template.json").abi
const apm = APM(web3, {ensRegistryAddress: aragonENS})

async function main(){
  const templateAddress = await apm.getLatestVersionContract("daonuts-template-v1.open.aragonpm.eth")
  console.log("templateAddress", templateAddress)
  const airdropDuoAddress = await apm.getLatestVersionContract("airdrop-duo-app.open.aragonpm.eth")
  console.log("airdropDuoAddress", airdropDuoAddress)
  const challengeAddress = await apm.getLatestVersionContract("challenge-app.open.aragonpm.eth")
  console.log("challengeAddress", challengeAddress)
  const subscribeAddress = await apm.getLatestVersionContract("subscribe-app.open.aragonpm.eth")
  console.log("subscribeAddress", subscribeAddress)
  const template = new ethers.Contract(templateAddress, TemplateABI, wallet);

  const txContribToken = await template.createToken("Contrib", 18, "CONTRIB", false, {gasLimit: 3000000})
  const txCurrencyToken = await template.createToken("Currency", 18, "CURRENCY", true, {gasLimit: 3000000})
  console.log("txContribToken")
  console.log("txCurrencyToken")
  await txContribToken.wait()
  await txCurrencyToken.wait()
  const txDao = await template.newInstance("Contrib", "Currency", {gasLimit: 7000000})
  console.log("txDao")
  const daoBlock = await txDao.wait()
  console.log(daoBlock.transactionHash)

  let templateWeb3 = new web3.eth.Contract(TemplateABI, templateAddress)
  const dao = await templateWeb3.getPastEvents('DeployDao', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.transactionHash===daoBlock.transactionHash)[0].returnValues.dao)
  console.log(`dao: ${dao}`)

  const votingAppId = namehash("voting.aragonpm.eth")
  const voting = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===votingAppId)[0].returnValues.appProxy)
  console.log(`voting: ${voting}`)

  const tokenManagerAppId = namehash("token-manager.aragonpm.eth")
  // take first (1) from filtered array because the currencyManager is the second token manager installed
  const tokenManagers = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===tokenManagerAppId).map(e=>e.returnValues.appProxy))

  console.log(`tokenManagers: ${tokenManagers}`)

  const txTemplateApps = await template.installApps(dao, voting, tokenManagers[0], tokenManagers[1], {gasLimit: 7000000})
  await txTemplateApps.wait()

}
main()

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
