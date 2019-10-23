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

import "@aragon/apps-token-manager/contracts/TokenManager.sol";
import "@aragon/apps-voting/contracts/Voting.sol";
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";

import "@daonuts/template-apps/contracts/TemplateApps.sol";

import "./TokenCache.sol";

contract Template is TokenCache {
    ENS public ens;
    DAOFactory public fac;
    MiniMeTokenFactory tokenFactory;

    //namehash("bare-kit.aragonpm.eth")
    bytes32 constant bareKitId = 0xf5ac5461dc6e4b6382eea8c2bc0d0d47c346537a4cb19fba07e96d7ef0edc5c0;
    //namehash("voting.aragonpm.eth")
    bytes32 constant votingAppId = 0x9fa3927f639745e587912d4b0fea7ef9013bf93fb907d29faeab57417ba6e1d4;
    //namehash("token-manager.aragonpm.eth")
    bytes32 constant tokenManagerAppId = 0x6b20a3010614eeebf2138ccec99f028a61c811b3b1a3343b6ff635985c75c91f;
    //namehash("daonuts-template-v1-apps.open.aragonpm.eth")
    bytes32 constant templateAppsId = 0xf8209b7d80297fa9400dfd54785753cae5e8c513c76c323306b46294b7d49739;

    event DeployDao(address dao);
    event InstalledApp(address appProxy, bytes32 appId);

    constructor(ENS _ens) public {
        ens = _ens;
        fac = Template(latestVersionAppBase(bareKitId)).fac();
        tokenFactory = new MiniMeTokenFactory();
    }

    function createToken(string _name, uint8 _decimals, string _symbol, bool _transferable) public {
        MiniMeToken token = tokenFactory.createCloneToken(MiniMeToken(0), 0, _name, _decimals, _symbol, _transferable);
        _cacheToken(token, msg.sender);
    }

    function newInstance(address[] _holders, string _guardianTokenName, string _currencyTokenName) public {
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        Voting voting = Voting(dao.newAppInstance(votingAppId, latestVersionAppBase(votingAppId)));

        TokenManager guardianTokenManager = TokenManager(dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId)));
        TokenManager currencyTokenManager = TokenManager(dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId)));

        MiniMeToken guardianToken = _popTokenCache(msg.sender, _guardianTokenName);
        guardianToken.changeController(guardianTokenManager);

        MiniMeToken currencyToken = _popTokenCache(msg.sender, _currencyTokenName);
        currencyToken.changeController(currencyTokenManager);

        // Initialize apps
        guardianTokenManager.initialize(guardianToken, false, 0);
        emit InstalledApp(guardianTokenManager, tokenManagerAppId);
        currencyTokenManager.initialize(currencyToken, true, 0);
        emit InstalledApp(currencyTokenManager, tokenManagerAppId);
        voting.initialize(guardianToken, uint64(60 * 10**16), uint64(15 * 10**16), uint64(1 days));
        emit InstalledApp(voting, votingAppId);

        _permissions(dao, acl, voting, guardianTokenManager, _holders, currencyTokenManager);
    }

    function _permissions(
        Kernel _dao, ACL _acl, Voting _voting, TokenManager _guardianTokenManager,
        address[] _holders, TokenManager _currencyTokenManager
    ) internal {
        bytes32 MINT_ROLE = _guardianTokenManager.MINT_ROLE();

        _acl.createPermission(_guardianTokenManager, _voting, _voting.CREATE_VOTES_ROLE(), _voting);
        _acl.createPermission(_voting, _guardianTokenManager, _guardianTokenManager.BURN_ROLE(), _voting);

        _acl.createPermission(this, _guardianTokenManager, MINT_ROLE, this);
        _mintHolders(_guardianTokenManager, _holders);

        _acl.grantPermission(_voting, _guardianTokenManager, MINT_ROLE);
        _acl.revokePermission(this, _guardianTokenManager, MINT_ROLE);
        _acl.setPermissionManager(_voting, _guardianTokenManager, MINT_ROLE);

        _acl.grantPermission(_voting, _dao, _dao.APP_MANAGER_ROLE());
        _acl.grantPermission(_voting, _acl, _acl.CREATE_PERMISSIONS_ROLE());

        emit DeployDao(_dao);
    }

    function installApps(Kernel _dao, Voting _voting, TokenManager _currencyTokenManager) public {
        ACL acl = ACL(_dao.acl());

        bytes32 APP_MANAGER_ROLE = _dao.APP_MANAGER_ROLE();
        bytes32 CREATE_PERMISSIONS_ROLE = acl.CREATE_PERMISSIONS_ROLE();

        TemplateApps templateApps = TemplateApps(latestVersionAppBase(templateAppsId));

        acl.grantPermission(templateApps, _dao, APP_MANAGER_ROLE);
        acl.revokePermission(this, _dao, APP_MANAGER_ROLE);
        acl.setPermissionManager(templateApps, _dao, APP_MANAGER_ROLE);

        acl.grantPermission(templateApps, acl, CREATE_PERMISSIONS_ROLE);
        acl.revokePermission(this, acl, CREATE_PERMISSIONS_ROLE);
        acl.setPermissionManager(templateApps, acl, CREATE_PERMISSIONS_ROLE);

        templateApps.install(_dao, _voting, _currencyTokenManager);
    }

    function _mintHolders(TokenManager _tokenManager, address[] _holders) internal {
        for (uint i=0; i<_holders.length; i++) {
            _tokenManager.mint(_holders[i], 1e18); // Give 1 token to each holder
        }
    }

    function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }

}
