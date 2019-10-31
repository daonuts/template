const namehash = require('eth-ens-namehash').hash
const names = [
  {name: "bare-kit.aragonpm.eth", variable: "bareKitId"},
  {name: "token-manager.aragonpm.eth", variable: "tokenManagerAppId"},
  {name: "daonuts-template1-apps.open.aragonpm.eth", variable: "templateAppsId"},
  {name: "airdrop-duo-app.open.aragonpm.eth", variable: "airdropDuoAppId"},
  {name: "capped-voting-app.open.aragonpm.eth", variable: "cappedVotingAppId"},
  {name: "challenge-app.open.aragonpm.eth", variable: "challengeAppId"},
  {name: "harberger-app.open.aragonpm.eth", variable: "harbergerAppId"},
  {name: "subscribe-app.open.aragonpm.eth", variable: "subscribeAppId"},
  {name: "tipping-app.open.aragonpm.eth", variable: "tippingAppId"}
]

names.forEach(({name, variable})=>{
  console.log(`//namehash("${name}")`)
  console.log(`bytes32 constant ${variable} = ${namehash(name)};`)
})
