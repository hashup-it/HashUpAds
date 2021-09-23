// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HashUpToken.sol";

/**
 * @title HashUp (Hash) Token standard
 * @notice Represents the HashUp token interface
 */
interface IHashupERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}

/**
 * @title HashUpAd standard
 * @notice Defines HashUpAd contract standard
 */
interface IHashUpAd {
    function getAdDay(
        uint16 day
    ) external returns (
        address,
        string memory,
        string memory,
        uint256,
        uint256,
        address,
        uint8
    );
}

/**
 * @title HashUp Ecosystem advertising-day state storage
 * @author HashUp.it (https://hashup.it)
 * @notice Use this contract to declare the time and content you want
 *  advertised
 */
contract HashUpAd is IHashUpAd {

    uint8 adID;

    mapping(uint16 => address) dayOwner;
    mapping(uint16 => string) urlForAd;
    mapping(uint16 => string) imageUrlForAd;
    mapping(uint16 => uint256) askPrice;
    mapping(uint16 => uint256) bidPrice;
    mapping(uint16 => address) bidPriceAddress;

    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea; // testnet BNB

    address creator;

    uint256 defaultAskPrice = 10 ** 18; // 10#

    HashUp HashUpToken;

    /**
     * @notice Emitted upon HashUp Ecosystem advertising-day state storage
     *  initialization; announces target HashUp Ecosystem web site
     * @param description Target HashUp Ecosystem web site ID string
     * @param creator Address of the contract deployer
     */
    event createAdSmartContract(string description, address creator);

    /**
     * @notice Emitted when advertisement asset properties are being set
     * @dev Event emission means the commodity owner has just made use of his
     *  obtained advertising space
     * @param day Index of the day whose advertising space has just had an
     *  advertising asset assigned to it
     * @param dayOwner Address of the subject commodity owner
     */
    event setDay(uint16 day, address dayOwner);
    /**
     * @notice Emitted upon commodity owner's lowest selling price announcement
     * @param day Index of the day being the transaction subject
     * @param price Ask price
     * @param askAddress Address of the commodity owner willing to sell
     *  the asset
     */
    event askDay(uint16 day, uint256 price, address askAddress);
    /**
     * @notice Emitted upon commodity potential buyer's bid proposal placement
     * @param day Index of the day being the transaction subject
     * @param price Placed bid price
     * @param bidAddress Address of the entity placing the bid
     */
    event bidDay(uint16 day, uint256 price, address bidAddress);
    /**
     * @notice Emitted upon a successful purchase of a commodity
     * @dev Triggered when transaction fired through means of the ask price
     * @param day Index of the day being the transaction subject
     * @param price Price at which the transaction has been carried out
     * @param newOwner Address of the post-transaction commodity owner
     */
    event buyDay(uint16 day, uint256 price, address newOwner);
    /**
     * @notice Emitted upon a successful sale of a commodity
     * @dev Triggered when transaction fired through means of the bid price
     * @param day Index of the day representing the advertising space being the
     *  transaction subject
     * @param price Price at which the commodity has been sold
     * @param oldOwner Address of the pre-transaction commodity owner
     * @param newOwner Address of the post-transaction commodity owner
     */
    event sellDay(
        uint16 day,
        uint256 price,
        address oldOwner,
        address newOwner
    );

    modifier isCanBuyFromAsk(uint16 day) {
        require(
            askPrice[day] <=
            HashUpToken.allowance(msg.sender, address(this))
        );
        _;
    }

    modifier isDayOwner(uint16 day) {
        require(msg.sender == dayOwner[day], "You have to be a day owner");
        _;
    }

    /**
     * @notice Creates a new auction for ad days on the HashUp Ecosystem
     * @dev Only the owner of a day can change days data. Days data are data of
     *  an advertisement
     * @param _HashUpToken HashUp Token for tests
     * @param _days Each day is 24h on HashUp pages
     * @param _adID Each ad place has its own ID
     */
    constructor(
        HashUp _HashUpToken,
        uint16 _days,
        uint8 _adID,
        string memory defaultAdUrl,
        string memory defaultAdImageUrl
    ) {
        for (uint16 day = 0; day < _days; day++) {
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
     * @notice Retrieves the contract deployer
     * @return Contract deployer retrieved
     */
    function getCreator() public view returns (address) {
        return creator;
    }

    /**
     * @notice Retrieves all data concerning the given day
     * @param day Index of the day for which the data is to be retrieved
     * @return Address of the commodity's current owner
     * @return URL resource of the commodity's advertisement asset
     * @return Image URL resource of the commodity's advertisement asset
     * @return Lowest price at which the advertising space owner is willing to
     *  have their commodity sold
     * @return Highest bid that has yet been proposed for the commodity since
     *  it was held by the current owner
     * @return Address of the entity whose bid has been registered as the
     *  highest for the commodity since it was held by the current owner
     * @return ID of the actual advertisement space location, representing
     *  a predefined place on one of the HashUp Ecosystem web pages
     */
    function getAdDay(
        uint16 day
    ) public override view returns (
        address,
        string memory,
        string memory,
        uint256,
        uint256,
        address,
        uint8
    ) {
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

    /**
     * @notice Retrieves the specified advertising-space's current owner
     * @param day Index of the day of whose advertising space owner is to be
     *  retrieved
     * @return Address of the commodity's current owner
     */
    function getOwnerOfDay(uint16 day) public view returns (address) {
        return dayOwner[day];
    }

    /**
     * @notice Sets the advertising space owner as the one specified
     * @param day Index of the day representing the commodity transferred
     * @param newOwner Address of the owner to whom the commodity ownership is
     *  being transferred
     * @return Address of the new owner set
     */
    function setOwnerOfDay(
        uint16 day,
        address newOwner
    ) public isDayOwner(day) returns (address) {
        dayOwner[day] = newOwner;
        return newOwner;
    }

    /**
     * @notice Utilises the owned commodity by means of placing any advertised
     *  content in the once purchased advertising space
     * @param day Index of the day for which the advertised asset's properties
     *  are to be set
     * @param _urlForAd Advertised asset URL resource
     * @param _imageUrlForAd Advertised asset image URL resource
     * @return `true` on successful asset properties allocation
     */
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

    /**
     * @notice Announces the lowest price at which the advertising space owner
     *  is willing to have it sold
     * @dev Note that it is (only) expected that the commodity will not be
     *  bought at a price lower than specified here
     * @param day Index of a day for which the ask price is to be declared
     * @param _price Declared ask price
     * @return The ask price just set
     */
    function askAd(
        uint16 day,
        uint256 _price
    ) public isDayOwner(day) returns (uint256) {
        askPrice[day] = _price;

        emit  askDay(day, _price, msg.sender);

        return _price;
    }

    /**
     * @notice Performs a purchase of the commodity priced at the owner-given
     *  ask price
     * @dev Entirely skips the buyers 'bidding' process, omitting any further
     *  interaction of the commodity owner
     * @param day Index of the day being the subject of the transaction
     * @return Transaction issuer's address
     */
    function buyFromAsk(
        uint16 day
    ) public isCanBuyFromAsk(day) returns (address) {

        HashUpToken.transferFrom(msg.sender, dayOwner[day], askPrice[day]);

        emit buyDay(day, askPrice[day], msg.sender);

        dayOwner[day] = msg.sender;
        askPrice[day] = defaultAskPrice;
        return msg.sender;
    }

    /**
     * @notice Places a bid on reserving an advertising space for the given day
     * @dev This is left pending until accepted; can be overwritten by a
     *  higher-priced bid
     * @param day The day for whose advertising space obtainment a bid is being
     *  placed
     * @param _price Placed bid price
     * @return The bid price just set
     */
    function bidAd(uint16 day, uint256 _price) public returns (uint256) {
        require(_price > bidPrice[day]);
        require(_price <= HashUpToken.allowance(msg.sender, address(this)));

        emit bidDay(day, _price, msg.sender);

        // require approve before;

        bidPrice[day] = _price;
        bidPriceAddress[day] = msg.sender;
        return _price;
    }

    /**
     * @notice Accepts the price proposal given by someone willing to advertise
     *  their content for the period of the particular day specified
     * @dev Can only be done by the day owner. Bidder (entity proposing the
     *  (price) becomes the day owner once the proposal gets accepted
     * @param day Index of a day for which the price proposal is to be accepted
     * @return Index of a day for which the price proposal has just been
     *  accepted
     */
    function sellToBid(uint16 day) public isDayOwner(day) returns (uint16) {
        require(
            bidPrice[day] ==
            HashUpToken.allowance(bidPriceAddress[day], address(this))
        );

        HashUpToken.transferFrom(
            bidPriceAddress[day],
            msg.sender,
            bidPrice[day]
        );

        emit sellDay(day, askPrice[day], dayOwner[day], msg.sender);

        bidPrice[day] = 0;
        dayOwner[day] = bidPriceAddress[day];
        bidPriceAddress[day] = creator;
        askPrice[day] = 100;

        return day;
    }
}
