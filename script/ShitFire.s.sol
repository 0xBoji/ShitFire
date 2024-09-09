// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {ShitNFT} from "../src/ShitFire.sol";
contract ShitNFTScript is Script {
    ShitNFT public ShitNFT;
    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        ShitNFT = new ShitNFT();
        vm.stopBroadcast();
    }
}