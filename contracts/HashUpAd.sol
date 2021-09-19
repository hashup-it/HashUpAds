// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HashUpToken.sol";

interface IHashupERC20 {
    function balanceOf(address account) external view returns (uint256);
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface IHashUpAd {
    function getAdDay(uint16 day) external returns (address, string memory, string memory, uint256, uint256, address, uint8);
}

contract HashUpAd is IHashUpAd {

    uint8 adID;

    mapping(uint16 => address) dayOwner;
    mapping(uint16 => string) urlForAd;
    mapping(uint16 => string) imageUrlForAd;
    mapping(uint16 => uint256) askPrice;
    mapping(uint16 => uint256) bidPrice; 
    mapping(uint16 => address) bidPriceAddress;
    
    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea; //testnet BNB
    
    address creator;
    
    uint256 defaultAskPrice = 10**18; //10#

    HashUp HashUpToken;
    
    event createAdSmartContract(string description, address creator);

    event setDay(uint16 day, address dayOwner);
    event askDay(uint16 day, uint256 price, address askAddress);
    event bidDay(uint16 day, uint256 price, address bidAddress);
    event buyDay(uint16 day, uint256 price, address newOwner);
    event sellDay(uint16 day, uint256 price, address oldOwner, address newOwner);

    modifier isCanBuyFromAsk(uint16 day) {
         require(askPrice[day] <= HashUpToken.allowance(msg.sender, address(this)));
         _;
    }
    
    modifier isDayOwner(uint16 day) {
        require(msg.sender == dayOwner[day], "You have to be an day owner");
        _;
    }
    
    /**
     * @notice Creates a new auction for a ad days on HashUp Ecosystem.
     * @dev Only the owner of a day can change days data.
     * @dev Days data are data of an advertisement.
     * @param _HashUpToken HashUp Token for tests.
     * @param _days Each day is 24h in HashUp pages. 
     * @param _adID Each ad place has own ID.
     */
    constructor(HashUp _HashUpToken, uint16 _days, uint8 _adID, string memory defaultAdUrl, string memory defaultAdImageUrl) {
        for(uint16 day = 0; day < _days; day++) {
            dayOwner[day] = msg.sender;
            urlForAd[day] = defaultAdUrl;
            imageUrlForAd[day] = defaultAdImageUrl;
            askPrice[day] = defaultAskPrice;
        }

        adID = _adID;

        HashUpToken = _HashUpToken;
        
        creator = msg.sender;
        emit createAdSmartContract("GameCap.io AD1", msg.sender);
    }
    
    /**
     * @notice Method for getting creator of contract. 
     */
    function getCreator() public view returns (address) {
        return creator;
    }
    
    
    /**
     * @notice Method for getting all data about the day.
     * @param day Index of day.
     */
    function getAdDay(uint16 day) public override view returns (address, string memory, string memory, uint256, uint256, address, uint8){
        return (
            dayOwner[day], 
            urlForAd[day], 
            imageUrlForAd[day], 
            askPrice[day], 
            bidPrice[day], 
            bidPriceAddress[day],
            adID
        );
    }

    function getOwnerOfDay(uint16 day) public view returns (address) {
        return dayOwner[day];
    }

    function setOwnerOfDay(uint16 day, address newOwner) public isDayOwner(day) returns (address) {
        dayOwner[day] = newOwner;
        return newOwner;
    }
    
    function setAdForDay(
        uint16 day, 
        string memory _urlForAd, 
        string memory _imageUrlForAd
    ) public isDayOwner(day) returns (bool) {
        emit setDay(day, msg.sender);
        
        urlForAd[day] = _urlForAd;
        imageUrlForAd[day] = _imageUrlForAd;
        
        return true;
    }
    
    function askAd(uint16 day, uint256 _price) public isDayOwner(day) returns (uint256) {
        askPrice[day] = _price;
        
        emit askDay(day, _price, msg.sender);
        
        return _price;
    }
    
    function buyFromAsk(uint16 day) public isCanBuyFromAsk(day) returns (address) {
        
        HashUpToken.transferFrom(msg.sender, dayOwner[day], askPrice[day]);
        
        emit buyDay(day, askPrice[day], msg.sender);
        
        dayOwner[day] = msg.sender;
        askPrice[day] = defaultAskPrice;
        return msg.sender;
    }
    
    function bidAd(uint16 day, uint256 _price) public returns (uint256) {
        require(_price > bidPrice[day]);
        require(_price <=  HashUpToken.allowance(msg.sender, address(this)));
        
        emit bidDay(day, _price, msg.sender);

        //require approve before;
        
        bidPrice[day] = _price;
        bidPriceAddress[day] = msg.sender;
        return _price;
    }
    
    function sellToBid(uint16 day) public isDayOwner(day) returns (uint16) {
        require(bidPrice[day] == HashUpToken.allowance(bidPriceAddress[day], address(this)));
        
        HashUpToken.transferFrom(bidPriceAddress[day], msg.sender, bidPrice[day]);
        
        emit sellDay(day, askPrice[day], dayOwner[day], msg.sender);
        
        bidPrice[day] = 0;
        dayOwner[day] = bidPriceAddress[day];
        bidPriceAddress[day] = creator;
        askPrice[day] = 100;
        
        return day;
    }
    
}