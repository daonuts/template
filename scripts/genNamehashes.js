const namehash = require('eth-ens-namehash').hash
const names = [
  {name: "bare-kit.aragonpm.eth", variable: "bareKitId"},
  {name: "airdrop-duo-app.open.aragonpm.eth", variable: "airdropDuoAppId"},
  {name: "subscribe-app.open.aragonpm.eth", variable: "subscribeAppId"},
  {name: "challenge-app.open.aragonpm.eth", variable: "challengeAppId"},
  {name: "tip-app.open.aragonpm.eth", variable: "tipAppId"},
  {name: "daonuts-template-v1-apps.open.aragonpm.eth", variable: "templateAppsId"},
  {name: "voting.aragonpm.eth", variable: "votingAppId"},
  {name: "token-manager.aragonpm.eth", variable: "tokenManagerAppId"}
]

names.forEach(({name, variable})=>{
  console.log(`//namehash("${name}")`)
  console.log(`bytes32 constant ${variable} = ${namehash(name)};`)
})
