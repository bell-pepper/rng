// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


    /**
    * @dev Interface of the Random RNG smart contract.
    */

interface IRandom {

    function generateSeed() external returns (uint256 seed);

    function generateNumberFromSeed(uint256 __seed, uint256 __max) external returns (uint256 number);

    function generateNumber(uint256 __max) external returns (uint256 number);

}

    /*
     * Use it for testing Random number generation smart contract as originaly contract doesn't output anything so use debug to have output loged as events
     */

contract Debug {

    event debug(uint256);

    function generateNumber(address __random, uint256 __max) external {
        (uint256 _number) = IRandom(__random).generateNumber(__max);
        emit debug(_number);
    }

    function generateSeed(address __random) external {
        (uint256 _seed) = IRandom(__random).generateSeed();
        emit debug(_seed);
    }

    function generateNumberFromSeed(address __random, uint256 __seed, uint256 __max) external {
        (uint256 _number) = IRandom(__random).generateNumberFromSeed(__seed, __max);
        emit debug(_number);
    }

}

    /**
     * Random number generation smart contract by pepper.meme to generate unpredictable number using seed and block hash that is unknown on generation moment.
     * To use it first generateSeed and store it in your contract, then on next request use generateNumberFromSeed that will give you desired random outcome.
     * If it's used for lotery or other activity that involves payments, payment should be deducted in first transaction where seed is generated.
     * Second transaction is used for execution when result outcome needs to be executed
     * If contract doesn't require high level of security generateNumber could be used to get instant result.
     */

contract Random is Ownable, IRandom {

    event TrustedPartyAdded(address indexed trustedParty);
    event TrustedPartyRemoved(address indexed trustedParty);

    uint256 private count;
    mapping(uint256 => uint256) private seeds;
    mapping(uint256 => bytes32) public blocks;
    mapping(address => bool) public trustedParties;
    uint256 public lastBlock;
    uint256[] public oldBlocks;

    function addTrustedParty(address __trustedParty) external onlyOwner {
        trustedParties[__trustedParty] = true;
        emit TrustedPartyAdded(__trustedParty);
    }

    function removeTrustedParty(address __trustedParty) external onlyOwner {
        trustedParties[__trustedParty] = false;
        emit TrustedPartyRemoved(__trustedParty);
    }

    modifier onlyTrustedParty() {
        require(trustedParties[msg.sender], "Caller is not trusted party");
        _;
    }

    function setBlockHash(uint256 __blockNumber, bytes32 __blockHash) external onlyTrustedParty {
        require(blocks[__blockNumber] == 0, "Block hash already set");
        for (uint256 __i = 0; __i < oldBlocks.length; __i++) {
            //we can only set blockHash if it's missing
            if (oldBlocks[__i] == __blockNumber) {
                blocks[__blockNumber] = __blockHash;
                if (oldBlocks.length - __i > 1) {
                    oldBlocks[__i] = oldBlocks[oldBlocks.length - 1];
                }
                oldBlocks.pop();
                break;
            }
        }
    }

    function getOldBlockCount() public view returns (uint256) {
        return oldBlocks.length;
    }

    function getLastBlockAge() public view returns (uint256) {
        if (lastBlock > 0) {
            return (block.number - lastBlock);
        }
        return (0);
    }

    function checkLastBlock() public {
        if (lastBlock > 0 && lastBlock != block.number) {
            if (lastBlock + 250 > block.number && uint256(blockhash(lastBlock)) > 0) {
                blocks[lastBlock] = blockhash(lastBlock);
            } else {
                oldBlocks.push(lastBlock);
            }
            lastBlock = 0;
        }
    }

    function _generateSeed() internal returns (uint256 seed) {
        checkLastBlock();
        seed = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, count, gasleft(), msg.sender)));
        //in case seed is 0 future checks would fail for it so we set it to 1
        if (seed == 0) {
            seed = 1;
        }
        count = uint256(keccak256(abi.encodePacked(block.timestamp, seed, gasleft())));
        return (seed);
    }

    function generateSeed() public returns (uint256 seed) {
        (seed) = _generateSeed();
        require(seeds[seed] == 0, "Seed already exists");
        lastBlock = block.number;
        seeds[seed] = block.number;
        return (seed);
    }

    function generateNumberFromSeed(uint256 __seed, uint256 __max) external returns (uint256 number) {
        checkLastBlock();
        require(seeds[__seed] > 0, "There is no such seed");
        require(blocks[seeds[__seed]] > 0, "Block hash is missing");
        number = uint256(keccak256(abi.encodePacked(seeds[__seed], blocks[seeds[__seed]]))) % __max + 1;
        return (number);
    }

    function generateNumber(uint256 __max) external returns (uint256 number) {
        (uint256 _seed) = _generateSeed();
        number = _seed % __max + 1;
        return (number);
    }

}
