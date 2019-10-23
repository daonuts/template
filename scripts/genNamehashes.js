const namehash = require('eth-ens-namehash').hash
const names = [
  {name: "bare-kit.aragonpm.eth", variable: "bareKitId"},
  {name: "airdrop-app.open.aragonpm.eth", variable: "airdropAppId"},
  {name: "subscription-app.open.aragonpm.eth", variable: "subscriptionAppId"},
  {name: "daonuts-template-v1-apps.open.aragonpm.eth", variable: "templateAppsId"},
  {name: "voting.aragonpm.eth", variable: "votingAppId"},
  {name: "token-manager.aragonpm.eth", variable: "tokenManagerAppId"}
]

names.forEach(({name, variable})=>{
  console.log(`//namehash("${name}")`)
  console.log(`bytes32 constant ${variable} = ${namehash(name)};`)
})
