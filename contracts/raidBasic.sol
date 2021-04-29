pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./raid.sol";

contract RaidBasic is Initializable, Raid, Util {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint64 internal staminaDrain;
    uint256[] weaponDrops; // given out randomly, we add them manually
    uint256 bounty; // split based on power
    uint8 bossTrait; // set manually for now

    uint256 totalPower;

    event SkillWinner(address addr, uint256 amount);
    event WeaponWinner(address addr, uint256 wepID);

    function initialize(address gameContract) public override initializer {
        Raid.initialize(gameContract);

        staminaDrain = 12 * 60 * 60;
    }

    function addRaider(uint256 characterID, uint256 weaponID) public override {
        require(characters.ownerOf(characterID) == msg.sender);
        require(weapons.ownerOf(weaponID) == msg.sender);
        require(participation[characterID] == false, "This character is already part of the raid");
        require(characters.getStaminaPoints(characterID) > 0, "You cannot join with 0 stamina");

        participation[characterID] = true;
        // we drain ~12h of stamina from the character
        // we may want to have a specific lockout in the future
        characters.setStaminaTimestamp(characterID, uint64(now + (staminaDrain)));

        int128 traitMultiplier = game.getPlayerTraitBonusAgainst(
            characters.getTrait(characterID),
            weapons.getTrait(weaponID),
            bossTrait
        );
        uint24 power = uint24(traitMultiplier.mulu(game.getPlayerFinalPower(characterID, weaponID)));
        totalPower += power;
        raiders.push(Raider(uint256(msg.sender), characterID, weaponID, power));
        emit RaiderJoined(msg.sender, characterID, weaponID, power);
    }

    function completeRaid(uint256 seed) public override restricted {
        require(completed == false, "Raid already completed, run reset first");
        completed = true;

        // TODO convert to giving xp instead (transfers cost a ton)
        // TODO come up with balanced formula for xp amount
        /*for(uint i = 0; i < raiders.length; i++) {
            characters.gainXp(raiders[i].charID, 20);
        }*/
        for(uint i = 0; i < raiders.length; i++) {
            Raider memory r = raiders[i];

            int128 powerPercentage = uint256(r.power).divu(totalPower);
            uint256 payout = powerPercentage.mulu(bounty);
            game.payPlayerConverted(address(r.owner), payout);
            emit SkillWinner(address(r.owner), payout);
        }

        for(uint i = 0; i < weaponDrops.length; i++) {
            Raider memory r = raiders[randomSeededMinMax(0, raiders.length-1, combineSeeds(seed,i))];
            game.approveContractWeaponFor(weaponDrops[i], address(this));
            weapons.transferFrom(address(game), address(r.owner), weaponDrops[i]);
            emit WeaponWinner(address(r.owner), weaponDrops[i]);
        }

        emit RaidCompleted();
    }

    function reset() public override restricted {
        totalPower = 0;
        bounty = 0;
        delete weaponDrops;
        super.reset();
    }

    function setBounty(uint256 to) public restricted {
        bounty = to;
    }

    function getBounty() public view returns(uint256) {
        return bounty;
    }

    function setBossTrait(uint8 trait) public restricted {
        bossTrait = trait;
    }

    function getTotalPower() public view returns(uint256) {
        return totalPower;
    }

    function addRewardWeapon(uint256 id) public restricted {
        require(weapons.ownerOf(id) == address(game), "Can only add weapons that belong to the main game contract");
        weaponDrops.push(id);
    }

    function mintRewardWeapon(uint256 stars, uint256 seed) public restricted {
        uint256 tokenId = weapons.mintWeaponWithStars(address(game), stars, seed);
        addRewardWeapon(tokenId);
    }

    function removeRewardWeapon(uint256 index) public restricted {
        require(index < weaponDrops.length, "Index out of bounds");

        delete weaponDrops[index];
    }

    function getWeaponDrops() public view returns(uint256[] memory) {
        return weaponDrops;
    }

    function setStaminaDrainSeconds(uint64 secs) public restricted {
        staminaDrain = secs;
    }

    function getStaminaDrainSeconds() public view returns(uint64) {
        return staminaDrain;
    }
}