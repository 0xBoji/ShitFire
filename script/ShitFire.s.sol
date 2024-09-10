// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {ShitNFT} from "../src/ShitFire.sol";

contract ShitNFTScript is Script {
    ShitNFT public shitNFTInstance; // Use the instance variable
    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        
        // Provide the required constructor arguments
        address airdropToken = 0x38007e72a8826401E5d9a893217Be33E42aB5dA0; 
        uint256 tokenPerNFT = 1000000000000000000; 
        address rewardToken = 0x38007e72a8826401E5d9a893217Be33E42aB5dA0; 
        uint256 rewardPerNFT = 1000000000000000000;
        
        shitNFTInstance = new ShitNFT(airdropToken, tokenPerNFT, rewardToken, rewardPerNFT);
        
        vm.stopBroadcast();
    }
}