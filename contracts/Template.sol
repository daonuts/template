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
import "@aragon/apps-voting/contracts/Voting.sol";
import "@daonuts/airdrop-duo/contracts/AirdropDuo.sol";
import "@daonuts/challenge/contracts/Challenge.sol";
import "@daonuts/subscribe/contracts/Subscribe.sol";
import "@daonuts/tipping/contracts/Tipping.sol";

/* import "@daonuts/template-apps/contracts/TemplateApps.sol"; */
import "../../template-apps/contracts/TemplateApps.sol";

import "./TokenCache.sol";

contract Template is TokenCache {
    ENS public ens;
    /* address public installer; */
    DAOFactory public fac;
    MiniMeTokenFactory tokenFactory;
    uint constant TOKEN_UNIT = 10 ** 18;
    address constant ANY_ENTITY = address(-1);

    //namehash("bare-kit.aragonpm.eth")
    bytes32 constant bareKitId = 0xf5ac5461dc6e4b6382eea8c2bc0d0d47c346537a4cb19fba07e96d7ef0edc5c0;
    //namehash("voting.aragonpm.eth")
    bytes32 constant votingAppId = 0x9fa3927f639745e587912d4b0fea7ef9013bf93fb907d29faeab57417ba6e1d4;
    //namehash("token-manager.aragonpm.eth")
    bytes32 constant tokenManagerAppId = 0x6b20a3010614eeebf2138ccec99f028a61c811b3b1a3343b6ff635985c75c91f;
    //namehash("daonuts-template1-apps.open.aragonpm.eth")
    bytes32 constant templateAppsId = 0x338e30976fd9d1e355a8c1ba2c9867f8ee304ebc0851ae6b14bc50592c53102e;
    //namehash("airdrop-duo-app.open.aragonpm.eth")
    bytes32 constant airdropDuoAppId = 0xa9e4c5b47fe3f0e61f6a7a045848bf59d44a5eaad3fbb6274929030a2030797d;
    //namehash("challenge-app.open.aragonpm.eth")
    bytes32 constant challengeAppId = 0x67c5438d71d05e58f99e88d6fb61ea5356b0f57106d3aba65c823267cc1cd07e;
    //namehash("subscribe-app.open.aragonpm.eth")
    bytes32 constant subscribeAppId = 0xb6461185219d266fa4eb5f1acad9b08a010bfd1e1f6a45fe3e169f161d8d5af1;
    //namehash("tipping-app.open.aragonpm.eth")
    bytes32 constant tippingAppId = 0x2d550bdd0046ce7aa5f255924dc9665972f04f1563519485689baf371e8d224b;

    event DeployDao(address dao);
    event InstalledApp(address appProxy, bytes32 appId);
    /* event Debug(address debug); */
    event DebugBool(bool debug);

    /* constructor(ENS _ens, address _installer) public { */
    constructor(ENS _ens) public {
        ens = _ens;
        fac = Template(latestVersionAppBase(bareKitId)).fac();
        tokenFactory = new MiniMeTokenFactory();
    }

    function createToken(string _name, uint8 _decimals, string _symbol, bool _transferable) public {
        MiniMeToken token = tokenFactory.createCloneToken(MiniMeToken(0), 0, _name, _decimals, _symbol, _transferable);
        _cacheToken(token, msg.sender);
    }

    /* function newInstance(string _contribTokenName, string _currencyTokenName, address _installer) public { */
    function newInstance(string _contribTokenName, string _currencyTokenName) public {
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        address voting = dao.newAppInstance(votingAppId, latestVersionAppBase(votingAppId));
        emit InstalledApp(voting, votingAppId);

        address contribManager = dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId));
        emit InstalledApp(contribManager, tokenManagerAppId);
        MiniMeToken contribToken = _popTokenCache(msg.sender, _contribTokenName);
        contribToken.changeController(contribManager);

        address currencyManager = dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId));
        emit InstalledApp(currencyManager, tokenManagerAppId);
        MiniMeToken currencyToken = _popTokenCache(msg.sender, _currencyTokenName);
        currencyToken.changeController(currencyManager);
        /* bool result = _installer.delegatecall(
                          bytes4(keccak256("install(address,address,address,address,address,address)")),
                          dao, voting, contribToken, contribManager, currencyToken, currencyManager); */
        /* require(result, "INSTALL_FAILED"); */
        /* _setup(dao, voting, contribToken, contribManager, currencyToken, currencyManager, _installer); */
        _setup(dao, voting, contribToken, contribManager, currencyToken, currencyManager);
        /* _permissions(acl, voting, contribManager, currencyManager, airdrop, challenge, subscribe, tipping); */
        _cleanup(dao, acl);

        emit DeployDao(dao);
    }

    function _setup(
      Kernel dao, address voting, address contribToken, address contribManager,
      address currencyToken, address currencyManager
    ) internal {
        address airdrop = dao.newAppInstance(airdropDuoAppId, latestVersionAppBase(airdropDuoAppId));
        emit InstalledApp(airdrop, airdropDuoAppId);
        address challenge = dao.newAppInstance(challengeAppId, latestVersionAppBase(challengeAppId));
        emit InstalledApp(challenge, challengeAppId);
        address subscribe = dao.newAppInstance(subscribeAppId, latestVersionAppBase(subscribeAppId));
        emit InstalledApp(subscribe, subscribeAppId);
        address tipping = dao.newAppInstance(tippingAppId, latestVersionAppBase(tippingAppId));
        emit InstalledApp(tipping, tippingAppId);

        bool result = latestVersionAppBase(templateAppsId)
                        .delegatecall(
                          bytes4(keccak256("install(address,address,address,address,address,address,address,address,address,address)")),
                          dao, voting, contribToken, contribManager, currencyToken, currencyManager, airdrop, challenge, subscribe, tipping);
        emit DebugBool(result);
    }

    function _cleanup(Kernel dao, ACL acl) internal {
        /* ACL acl = ACL(_dao.acl()); */
        bytes32 APP_MANAGER_ROLE = dao.APP_MANAGER_ROLE();
        bytes32 CREATE_PERMISSIONS_ROLE = acl.CREATE_PERMISSIONS_ROLE();

        acl.grantPermission(msg.sender, dao, APP_MANAGER_ROLE);
        acl.revokePermission(this, dao, APP_MANAGER_ROLE);
        acl.setPermissionManager(msg.sender, dao, APP_MANAGER_ROLE);

        acl.grantPermission(msg.sender, acl, CREATE_PERMISSIONS_ROLE);
        acl.revokePermission(this, acl, CREATE_PERMISSIONS_ROLE);
        acl.setPermissionManager(msg.sender, acl, CREATE_PERMISSIONS_ROLE);
    }

    /* function _mintHolders(TokenManager _tokenManager, address[] _holders) internal {
        for (uint i=0; i<_holders.length; i++) {
            _tokenManager.mint(_holders[i], 1 * 10**18); // Give 1 token to each holder
        }
    } */

    function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }

}
