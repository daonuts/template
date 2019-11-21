/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 *
 * This file requires contract dependencies which are licensed as
 * GPL-3.0-or-later, forcing it to also be licensed as such.
 *
 * This is the only file in your project that requires this license and
 * you are free to choose a different license for the rest of the project.
 */

pragma solidity ^0.4.24;

import "@aragon/os/contracts/factory/DAOFactory.sol";
import "@aragon/os/contracts/apm/Repo.sol";
import "@aragon/os/contracts/lib/ens/ENS.sol";
import "@aragon/os/contracts/lib/ens/PublicResolver.sol";

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/apps-token-manager/contracts/TokenManager.sol";
import "@aragon/apps-agent/contracts/Agent.sol";
/* import "@aragon/apps-voting/contracts/Voting.sol"; */

import "@daonuts/token/contracts/Token.sol";
import "@daonuts/airdrop-duo/contracts/AirdropDuo.sol";
import "@daonuts/challenge/contracts/Challenge.sol";
import "@daonuts/subscribe/contracts/Subscribe.sol";
import "@daonuts/tipping/contracts/Tipping.sol";
import "@daonuts/capped-voting/contracts/CappedVoting.sol";

/* import "@daonuts/template-apps/contracts/TemplateApps.sol"; */
import "../../template-apps/contracts/TemplateApps.sol";

import "./TokenCache.sol";

contract Template is TokenCache {
    ENS public ens;
    /* address public installer; */
    DAOFactory public fac;
    /* MiniMeTokenFactory tokenFactory; */
    uint constant TOKEN_UNIT = 10 ** 18;
    address constant ANY_ENTITY = address(-1);

    //namehash("bare-kit.aragonpm.eth")
    bytes32 constant bareKitId = 0xf5ac5461dc6e4b6382eea8c2bc0d0d47c346537a4cb19fba07e96d7ef0edc5c0;
    //namehash("token-manager.aragonpm.eth")
    bytes32 constant tokenManagerAppId = 0x6b20a3010614eeebf2138ccec99f028a61c811b3b1a3343b6ff635985c75c91f;
    //namehash("agent.aragonpm.eth")
    bytes32 constant agentAppId = 0x9ac98dc5f995bf0211ed589ef022719d1487e5cb2bab505676f0d084c07cf89a;
    //namehash("daonuts-template1-apps.open.aragonpm.eth")
    bytes32 constant templateAppsId = 0x338e30976fd9d1e355a8c1ba2c9867f8ee304ebc0851ae6b14bc50592c53102e;
    //namehash("airdrop-duo-app.open.aragonpm.eth")
    bytes32 constant airdropDuoAppId = 0xa9e4c5b47fe3f0e61f6a7a045848bf59d44a5eaad3fbb6274929030a2030797d;
    //namehash("capped-voting-app.open.aragonpm.eth")
    bytes32 constant cappedVotingAppId = 0xc255a5b08654df1ec932ab5c2e0d7b58809eb0499b6ea6a46a3029051b648446;
    //namehash("challenge-app.open.aragonpm.eth")
    bytes32 constant challengeAppId = 0x67c5438d71d05e58f99e88d6fb61ea5356b0f57106d3aba65c823267cc1cd07e;
    //namehash("harberger-app.open.aragonpm.eth")
    bytes32 constant harbergerAppId = 0xe2998d9700224635282e9c2da41222441463aa25bcf3bb5252b716e3c6045f95;
    //namehash("subscribe-app.open.aragonpm.eth")
    bytes32 constant subscribeAppId = 0xb6461185219d266fa4eb5f1acad9b08a010bfd1e1f6a45fe3e169f161d8d5af1;
    //namehash("tipping-app.open.aragonpm.eth")
    bytes32 constant tippingAppId = 0x2d550bdd0046ce7aa5f255924dc9665972f04f1563519485689baf371e8d224b;


    event DeployDao(address dao);
    event InstalledApp(address appProxy, bytes32 appId);
    event DEBUG(bool debug);

    /* constructor(ENS _ens, address _installer) public { */
    constructor(ENS _ens) public {
        ens = _ens;
        fac = Template(latestVersionAppBase(bareKitId)).fac();
        /* tokenFactory = new MiniMeTokenFactory(); */
    }

    function createToken(string _name, uint8 _decimals, string _symbol, bool _transferable) public {
        /* MiniMeToken token = tokenFactory.createCloneToken(MiniMeToken(0), 0, _name, _decimals, _symbol, _transferable); */
        Token token = new Token(_name, _decimals, _symbol, _transferable);
        _cacheToken(token, msg.sender);
    }

    /* function newInstance(string _contribName, string _currencyName, address _installer) public { */
    function newInstance(string _contribName, string _contribSymbol, string _currencyName, string _currencySymbol) public {
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        address contribManager = dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId));
        emit InstalledApp(contribManager, tokenManagerAppId);
        Token contrib = new Token(_contribName, 18, _contribSymbol, false);//_popTokenCache(msg.sender, _contribName);
        contrib.changeController(contribManager);
        TokenManager(contribManager).initialize(MiniMeToken(contrib), false, 0);

        address currencyManager = dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId));
        emit InstalledApp(currencyManager, tokenManagerAppId);
        Token currency = new Token(_currencyName, 18, _currencySymbol, true);//_popTokenCache(msg.sender, _currencyName);
        currency.changeController(currencyManager);
        TokenManager(currencyManager).initialize(MiniMeToken(currency), true, 0);

        /* _setup(dao, voting, contrib, contribManager, currency, currencyManager); */
        /* _cleanup(dao, acl); */

        emit DeployDao(dao);
    }

    function setup(
      Kernel dao, address contribManager, address currencyManager, address initialAdmin, bytes32 airdropRoot, string airdropDataURI
    ) public {
        address airdrop = dao.newAppInstance(airdropDuoAppId, latestVersionAppBase(airdropDuoAppId));
        emit InstalledApp(airdrop, airdropDuoAppId);

        AirdropDuo(airdrop).initialize(contribManager, currencyManager, airdropRoot, airdropDataURI);

        _installSetA(dao, contribManager, currencyManager, airdrop);
        _installSetB(dao, currencyManager);

        _cleanup(dao);
    }

    function _installSetA(
      Kernel dao, address contribManager, address currencyManager, address airdrop
    ) internal {
        address voting = dao.newAppInstance(cappedVotingAppId, latestVersionAppBase(cappedVotingAppId));
        emit InstalledApp(voting, cappedVotingAppId);
        address challenge = dao.newAppInstance(challengeAppId, latestVersionAppBase(challengeAppId));
        emit InstalledApp(challenge, challengeAppId);

        bool resultSetA = latestVersionAppBase(templateAppsId)
                        .delegatecall(
                          bytes4(keccak256("installSetA(address,address,address,address,address,address)")),
                          dao, voting, contribManager, currencyManager, airdrop, challenge);

        emit DEBUG(resultSetA);
    }

    function _installSetB(Kernel dao, address currencyManager) internal {
        address harberger = dao.newAppInstance(harbergerAppId, latestVersionAppBase(harbergerAppId));
        emit InstalledApp(harberger, harbergerAppId);
        address subscribe = dao.newAppInstance(subscribeAppId, latestVersionAppBase(subscribeAppId));
        emit InstalledApp(subscribe, subscribeAppId);
        address tipping = dao.newAppInstance(tippingAppId, latestVersionAppBase(tippingAppId));
        emit InstalledApp(tipping, tippingAppId);
        address agent = dao.newAppInstance(agentAppId, latestVersionAppBase(agentAppId));
        emit InstalledApp(agent, agentAppId);

        bool resultSetB = latestVersionAppBase(templateAppsId)
                        .delegatecall(
                          bytes4(keccak256("installSetB(address,address,address,address,address,address)")),
                          dao, currencyManager, harberger, subscribe, tipping, agent);

        emit DEBUG(resultSetB);
    }

    function _cleanup(Kernel dao) internal {
        ACL acl = ACL(dao.acl());
        bytes32 APP_MANAGER_ROLE = dao.APP_MANAGER_ROLE();
        bytes32 CREATE_PERMISSIONS_ROLE = acl.CREATE_PERMISSIONS_ROLE();

        acl.grantPermission(msg.sender, dao, APP_MANAGER_ROLE);
        acl.revokePermission(this, dao, APP_MANAGER_ROLE);
        acl.setPermissionManager(msg.sender, dao, APP_MANAGER_ROLE);

        acl.grantPermission(msg.sender, acl, CREATE_PERMISSIONS_ROLE);
        acl.revokePermission(this, acl, CREATE_PERMISSIONS_ROLE);
        acl.setPermissionManager(msg.sender, acl, CREATE_PERMISSIONS_ROLE);
    }

    function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }

}
