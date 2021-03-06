pragma solidity ^0.4.24;

import {DSTest} from "ds-test/test.sol";
import {DSValue} from "ds-value/value.sol";
import {DSRoles} from "ds-roles/roles.sol";

import {GemJoin, ETHJoin} from "dss/join.sol";
import {GemMove} from 'dss/move.sol';

import "./DssDeploy.sol";

import {WarpDrip} from "dss/drip.t.sol";
import {WarpFlip} from "dss/flip.t.sol";
import {WarpFlap} from "dss/flap.t.sol";
import {WarpFlop} from "dss/flop.t.sol";

import {MomLib} from "./momLib.sol";

contract WarpDripFab {
    function newDrip(Vat vat) public returns (Drip drip) {
        drip = new WarpDrip(vat);
        drip.rely(msg.sender);
    }
}

contract WarpFlipFab {
    function newFlip(address dai, address gem) public returns (Flipper flop) {
        flop = new WarpFlip(dai, gem);
    }
}

contract WarpFlapFab {
    function newFlap(address dai, address gov) public returns (Flapper flap) {
        flap = new WarpFlap(dai, gov);
    }
}

contract WarpFlopFab {
    function newFlop(address dai, address gov) public returns (Flopper flop) {
        flop = new WarpFlop(dai, gov);
        flop.rely(msg.sender);
    }
}

contract FakeUser {
    function doApproval(DSToken token, address guy) public {
        token.approve(guy);
    }

    function doDaiJoin(DaiJoin obj, bytes32 urn, uint wad) public {
        obj.join(urn, wad);
    }

    function doEthJoin(ETHJoin obj, bytes32 addr, uint wad) public {
        obj.join.value(wad)(addr);
    }

    function doFrob(Pit obj, bytes32 ilk, int dink, int dart) public {
        obj.frob(ilk, dink, dart);
    }

    function doHope(DaiMove obj, address guy) public {
        obj.hope(guy);
    }

    function doTend(Flipper obj, uint id, uint lot, uint bid) public {
        obj.tend(id, lot, bid);
    }

    function doDent(Flipper obj, uint id, uint lot, uint bid) public {
        obj.dent(id, lot, bid);
    }

    function doDeal(Flipper obj, uint id) public {
        obj.deal(id);
    }

    function() public payable {
    }
}

contract DssDeployTest is DSTest {
    VatFab vatFab;
    PitFab pitFab;
    WarpDripFab dripFab;
    VowFab vowFab;
    CatFab catFab;
    TokenFab tokenFab;
    GuardFab guardFab;
    DaiJoinFab daiJoinFab;
    DaiMoveFab daiMoveFab;
    WarpFlapFab flapFab;
    WarpFlopFab flopFab;
    WarpFlipFab flipFab;
    SpotFab spotFab;
    ProxyFab proxyFab;

    DssDeploy dssDeploy;

    DSToken gov;
    DSValue pipETH;
    DSValue pipDGX;

    DSRoles authority;

    ETHJoin ethJoin;
    GemJoin dgxJoin;

    Vat vat;
    Pit pit;
    Drip drip;
    Vow vow;
    Cat cat;
    Spotter ethPrice;
    DSToken dai;
    DaiJoin daiJoin;
    DaiMove daiMove;

    Flipper ethFlip;

    FakeUser user1;
    FakeUser user2;

    MomLib momLib;

    // --- Math ---
    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function setUp() public {
        vatFab = new VatFab();
        pitFab = new PitFab();
        dripFab = new WarpDripFab();
        vowFab = new VowFab();
        catFab = new CatFab();
        tokenFab = new TokenFab();
        guardFab = new GuardFab();
        daiJoinFab = new DaiJoinFab();
        daiMoveFab = new DaiMoveFab();
        flapFab = new WarpFlapFab();
        flopFab = new WarpFlopFab();
        proxyFab = new ProxyFab();

        flipFab = new WarpFlipFab();
        spotFab = new SpotFab();

        uint startGas = gasleft();
        dssDeploy = new DssDeploy(
            vatFab,
            pitFab,
            DripFab(dripFab),
            vowFab,
            catFab,
            tokenFab,
            guardFab,
            daiJoinFab,
            daiMoveFab,
            FlapFab(flapFab),
            FlopFab(flopFab),
            FlipFab(flipFab),
            spotFab,
            proxyFab
        );
        uint endGas = gasleft();
        emit log_named_uint("Deploy DssDeploy", startGas - endGas);

        gov = new DSToken("GOV");
        pipETH = new DSValue();
        pipDGX = new DSValue();
        authority = new DSRoles();
        authority.setRootUser(this, true);

        user1 = new FakeUser();
        user2 = new FakeUser();
        address(user1).transfer(100 ether);
        address(user2).transfer(100 ether);
    }

    function file(address who, uint data) external {
        who;data;
        dssDeploy.mom().execute(momLib, msg.data);
    }

    function file(address who, bytes32 what, uint data) external {
        who;what;data;
        dssDeploy.mom().execute(momLib, msg.data);
    }

    function file(address who, bytes32 ilk, bytes32 what, uint data) external {
        who;ilk;what;data;
        dssDeploy.mom().execute(momLib, msg.data);
    }

    function deploy() public {
        dssDeploy.deployVat();
        dssDeploy.deployPit();
        dssDeploy.deployDai();
        dssDeploy.deployTaxation(gov);
        dssDeploy.deployLiquidation(gov);
        dssDeploy.deployMom(authority);

        vat = dssDeploy.vat();
        pit = dssDeploy.pit();
        drip = dssDeploy.drip();
        vow = dssDeploy.vow();
        cat = dssDeploy.cat();
        dai = dssDeploy.dai();
        daiJoin = dssDeploy.daiJoin();
        daiMove = dssDeploy.daiMove();

        ethJoin = new ETHJoin(vat, "ETH");
        GemMove ethMove = new GemMove(vat, "ETH");
        dssDeploy.deployCollateral("ETH", ethJoin, ethMove, pipETH);

        DSToken dgx = new DSToken("DGX");
        dgxJoin = new GemJoin(vat, "DGX", dgx);
        GemMove dgxMove = new GemMove(vat, "DGX");
        dssDeploy.deployCollateral("DGX", dgxJoin, dgxMove, pipDGX);

        // Set Params
        momLib = new MomLib();
        this.file(address(pit), bytes32("Line"), uint(10000 ether));
        this.file(address(pit), bytes32("ETH"), bytes32("line"), uint(10000 ether));

        pipETH.poke(300 * 10 ** 18); // Price 300 DAI = 1 ETH (precision 18)
        (ethFlip,,, ethPrice) = dssDeploy.ilks("ETH");
        this.file(address(ethPrice), uint(1500000000 ether)); // Liquidation ratio 150%
        ethPrice.poke();
        (uint spot, ) = pit.ilks("ETH");
        assertEq(spot, 300 * ONE * ONE / 1500000000 ether);
    }

    function testDeploy() public {
        deploy();
    }

    function testFailDeploy() public {
        dssDeploy.deployPit();
    }

    function testFailDeploy2() public {
        dssDeploy.deployVat();
        dssDeploy.deployTaxation(gov);
    }

    function testFailDeploy3() public {
        dssDeploy.deployVat();
        dssDeploy.deployPit();
        dssDeploy.deployDai();
        dssDeploy.deployLiquidation(gov);
    }

    function testFailDeploy4() public {
        dssDeploy.deployVat();
        dssDeploy.deployPit();
        dssDeploy.deployDai();
        dssDeploy.deployTaxation(gov);
        dssDeploy.deployMom(authority);
    }

    function testJoinCollateral() public {
        deploy();
        assertEq(vat.gem("ETH", bytes32(address(this))), 0);
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        assertEq(vat.gem("ETH", bytes32(address(this))), mul(ONE, 1 ether));
    }

    function testExitCollateral() public {
        deploy();
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        ethJoin.exit(address(this), 1 ether);
        assertEq(vat.gem("ETH", bytes32(address(this))), 0);
    }

    function testDrawDai() public {
        deploy();
        assertEq(dssDeploy.dai().balanceOf(address(this)), 0);
        ethJoin.join.value(1 ether)(bytes32(address(this)));

        pit.frob("ETH", 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", bytes32(address(this))), mul(ONE, 0.5 ether));
        assertEq(vat.dai(bytes32(address(this))), mul(ONE, 60 ether));

        dssDeploy.daiJoin().exit(address(this), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(bytes32(address(this))), 0);
    }

    function testDrawDaiLimit() public {
        deploy();
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 100 ether); // 0.5 * 300 / 1.5 = 100 DAI max
    }

    function testFailDrawDaiLimit() public {
        deploy();
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 100 ether + 1);
    }

    function testPaybackDai() public {
        deploy();
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 60 ether);
        dssDeploy.daiJoin().exit(address(this), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 60 ether);
        dssDeploy.dai().approve(dssDeploy.daiJoin(), uint(-1));
        dssDeploy.daiJoin().join(bytes32(address(this)), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 0);

        assertEq(vat.dai(bytes32(address(this))), mul(ONE, 60 ether));
        pit.frob("ETH", 0 ether, -60 ether);
        assertEq(vat.dai(bytes32(address(this))), 0);
    }

    function testFailBite() public {
        deploy();
        ethJoin.join.value(1 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 100 ether); // Maximun DAI

        cat.bite("ETH", bytes32(address(this)));
    }

    function testBite() public {
        deploy();
        ethJoin.join.value(0.5 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 100 ether); // Maximun DAI generated

        pipETH.poke(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        ethPrice.poke();

        (uint ink, uint art) = vat.urns("ETH", bytes32(address(this)));
        assertEq(ink, 0.5 ether);
        assertEq(art, 100 ether);
        cat.bite("ETH", bytes32(address(this)));
        (ink, art) = vat.urns("ETH", bytes32(address(this)));
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function testFlip() public {
        deploy();
        ethJoin.join.value(0.5 ether)(bytes32(address(this)));
        pit.frob("ETH", 0.5 ether, 100 ether); // Maximun DAI generated
        pipETH.poke(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        ethPrice.poke();
        uint nflip = cat.bite("ETH", bytes32(address(this)));
        assertEq(vat.gem("ETH", bytes32(address(ethFlip))), 0);
        uint batchId = cat.flip(nflip, 100 ether);
        assertEq(vat.gem("ETH", bytes32(address(ethFlip))), mul(0.5 ether, ONE));
        address(user1).transfer(10 ether);
        user1.doEthJoin(ethJoin, bytes32(address(user1)), 10 ether);
        user1.doFrob(pit, "ETH", 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(ethJoin, bytes32(address(user2)), 10 ether);
        user2.doFrob(pit, "ETH", 10 ether, 1000 ether);

        user1.doHope(daiMove, ethFlip);
        user2.doHope(daiMove, ethFlip);

        user1.doTend(ethFlip, batchId, 0.5 ether, 50 ether);
        user2.doTend(ethFlip, batchId, 0.5 ether, 70 ether);
        user1.doTend(ethFlip, batchId, 0.5 ether, 90 ether);
        user2.doTend(ethFlip, batchId, 0.5 ether, 100 ether);

        user1.doDent(ethFlip, batchId, 0.4 ether, 100 ether);
        user2.doDent(ethFlip, batchId, 0.35 ether, 100 ether);
        WarpFlip(ethFlip).warp(ethFlip.ttl() - 1);
        user1.doDent(ethFlip, batchId, 0.3 ether, 100 ether);
        WarpFlip(ethFlip).warp(ethFlip.era() + ethFlip.ttl() + 1);
        user1.doDeal(ethFlip, batchId);
    }

    function() public payable {
    }
}
