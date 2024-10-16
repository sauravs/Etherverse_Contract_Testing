//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../nft/interface/IEtherverseNFT.sol";
import {Price, Upgrade, Asset} from "../nft/lib/Structs.sol";
import "../common/EtherverseUser.sol";

// TODO: Decide on which approach to take for making sure the functions are only called by valid users.
contract Game is EtherverseUser, ERC721Holder {
    using SafeERC20 for IERC20;
    IERC20 public USDC;
    string public name;
    struct Order {
        address nft;
        uint256 tokenId;
        uint256 price;
        uint256 fee;
        uint256 totalPrice;
        uint256 orderCompleted;
    }

    // 0x0C903F1C518724CBF9D00b18C2Db5341fF68269C,0x762aD31Ff4bD1ceb5b3b5868672d5CBEaEf609dF,0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904,0x926E109ad836DC3DCb138Af4a8C1bd790E675C93,900,900,"Game"
    enum RewardType {  //@audit where RewardType is being used?
        NFT,
        ERC20Token,
        NativeToken
    }                                       // 

    uint256 public freeUpgradeInput;
    uint256 public paidUpgradeInput;
    uint256 public orderCount;
    uint256 public marketFee;                    //what is marketFee? Cut web3tech ,asset creator or gamedeveloper will take?
    address public upgradeAddress;
    mapping(uint256 => Order) public orders;

    event OrderCreated(
        uint256 indexed orderId,
        address indexed seller,
        uint256 indexed timestamp
    );
    event OrderExecuted(
        uint256 indexed orderId,
        address indexed buyer,
        uint256 indexed timestamp
    );

    modifier onlyGameDev() {
        require(msg.sender == user, "UnauthorizedAccess");
        _;
    }

    constructor(
        address _etherverse,
        address _user,
        address _userWallet,
        address _usdcToken,
        address _upgrade,
        address initialOwner,
        uint256 _marketFee,
        uint256 _etherverseFee,
        string memory _name
    )
        EtherverseUser(
            _etherverse,
            _user,       // account made for doing write operation
            _userWallet,  // external wallet where fee amount will be received onlyOwnerOr(user)
            _etherverseFee,
            initialOwner  //@audit what is initialOwner here
        )
    {
        name = _name;
        // "Game Name";
        USDC = IERC20(_usdcToken);
        // IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        marketFee = _marketFee;
        // 4269 = 42.69%
        upgradeAddress = _upgrade;
    }

    function setMarketFee(uint256 _marketFee) external onlyOwnerOr(user) {
        require(_marketFee < 10000, "Market fee must be less than 100%");   //@audit -critical- high  (_marketFee > 10000) incorrect equality ,it should be less than 100%,updating to marketFee < 10000 to continue testing further
        marketFee = _marketFee;
    }

    function createOrder(             //@audit  so basically this need to be placed by users who owns the nft (secoondry market place)
        address _nft,                 // price = 10$  // marketFee will be set by gamedeveloper..suppose he set marketfee =10% ,then he will recieve 1 $ as a commisioon(gamedeveloper)
        uint256 _tokenId,
        uint256 _price
    ) external nonReentrant {
        require(_nft != address(0), "Invalid Address");
        IERC721 nft = IERC721(_nft);
        require(
            nft.getApproved(_tokenId) == address(this) ||
                nft.isApprovedForAll(nft.ownerOf(_tokenId), address(this)),
            "Contract not approved to transfer NFT"
        );

        orders[orderCount] = Order(
            _nft,
            _tokenId,
            _price - (marketFee * _price) / 10000,
            (marketFee * _price) / 10000,
            _price,
            0
        );
        emit OrderCreated(orderCount, msg.sender, block.timestamp);
        orderCount++;
    }

    function executeOrder(uint256 _orderId) external nonReentrant {    //any buyer who wants to buy that crated order nft

        Order memory order = orders[_orderId];
        require(order.orderCompleted == 0, "Order already completed");

        IERC721 nft = IERC721(order.nft);
        address nftOwner = nft.ownerOf(order.tokenId);

        if (order.fee != 0) {
            USDC.safeTransferFrom(msg.sender, address(this), order.fee);  //@audit- high - 
// passing an arbitrary `from` address to `transferFrom` (or `safeTransferFrom`) can lead to loss of funds, because anyone can transfer tokens from the `from` address if an approval is made

        }
        USDC.safeTransferFrom(msg.sender, nftOwner, order.price);  // if fee = 0 // gameDeveloper has set 0 fee .
        nft.safeTransferFrom(nftOwner, msg.sender, order.tokenId);

        orders[_orderId].orderCompleted = block.timestamp;
        emit OrderExecuted(_orderId, msg.sender, block.timestamp);
    }

    function getOrder(uint256 _orderId) external view returns (Order memory) {
        return orders[_orderId];
    }

    function getAllOrders() external view returns (Order[] memory) {
        Order[] memory listOfOrders = new Order[](orderCount);
        for (uint256 i; i < orderCount; i++) {
            listOfOrders[i] = orders[i];
        }
        return listOfOrders;
    }

    function setUpgradeModule(address _upgrade) external onlyOwner {
        upgradeAddress = _upgrade;
    }

    function setUpgradePricing(
        address _nft,
        uint256 _price,
        uint256 _split
    ) external onlyOwnerOr(user) {
        Price memory opts = IEtherverseNFT(_nft).upgradePricing(
            address(this)
        );
        IEtherverseNFT(_nft).setUpgradePricing(
            _price == 0 ? opts.amount : _price,
            _split == 0 ? opts.split : _split
        );
    }

    function mint(
        address _nft,
        address to,
        bytes memory authorizationParams
    ) external returns (uint256) {
        return IEtherverseNFT(_nft).mint(to, authorizationParams);
    }

    function freeUpgrade(address _nft, uint256 tokenId) external {
        IEtherverseNFT(_nft).freeUpgrade(tokenId);
    }

    function paidUpgrade(
        address _nft,
        uint256 tokenId,
        bytes memory authorizationParams
    ) external {
        IEtherverseNFT(_nft).paidUpgrade(tokenId, authorizationParams);
    }

    function nextUpgrade(
        address _nft,
        uint256 tokenId,
        Upgrade.Type _type
    ) external view returns (Asset.Stat memory) {
        Asset.Stat memory upgrade = IEtherverseNFT(_nft).nextUpgrade(
            tokenId,
            _type
        );
        Asset.Stat memory base = IEtherverseNFT(_nft).baseStat();
        return
            Asset.Stat(
                upgrade.stat1 + base.stat1,
                upgrade.stat2 + base.stat2,
                upgrade.stat3 + base.stat3
            );
    }

    function nextUpgradePrice(
        address _nft,
        uint256 tokenId
    ) external view returns (uint256) {
        return IEtherverseNFT(_nft).nextUpgradePrice(tokenId);
    }
}
