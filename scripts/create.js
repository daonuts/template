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
  const template = new ethers.Contract(templateAddress, TemplateABI, wallet);

  const txGuardianToken = await template.createToken("Guardian", 18, "GUARD", false, {gasLimit: 3000000})
  const txCurrencyToken = await template.createToken("Currency", 18, "PLAY", true, {gasLimit: 3000000})
  console.log("txGuardianToken")
  console.log("txCurrencyToken")
  await txGuardianToken.wait()
  await txCurrencyToken.wait()
  const txDao = await template.newInstance([wallet.address], "Guardian", "Currency", {gasLimit: 7000000})
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
  // take first (1) from filtered array because the currencyTokenManager is the second token manager installed
  const currencyTokenManager = await templateWeb3.getPastEvents('InstalledApp', {fromBlock: daoBlock.blockNumber, toBlock: daoBlock.blockNumber})
    .then(events=>events.filter(e=>e.returnValues.appId===tokenManagerAppId)[1].returnValues.appProxy)
  console.log(`currencyTokenManager: ${currencyTokenManager}`)

  const txTemplateApps = await template.installApps(dao, voting, currencyTokenManager, {gasLimit: 7000000})
  await txTemplateApps.wait()

}
main()
