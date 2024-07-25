//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../nft/interface/IRPG.sol";
import {Upgrade} from "../nft/lib/RPGStruct.sol";
import "../common/Etherverse.sol";

// TO-DO: Decide on which approach to take for making sure the functions are only called by valid users.
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
    enum RewardType {
        NFT,
        ERC20Token,
        NativeToken
    }

    uint256 public freeUpgradeInput;
    uint256 public paidUpgradeInput;
    uint256 public orderCount;
    uint256 public marketFee;
    address public upgradeAddress;
    mapping(uint256 => Order) public orders;

    event OrderCreated(uint256 indexed orderId, address indexed seller, uint256 indexed timestamp);
    event OrderExecuted(uint256 indexed orderId, address indexed buyer, uint256 indexed timestamp);

    // TO-DO: Need to use rolebased access control instead of this
    modifier onlyEtherverse() {
        require(msg.sender == etherverse, "UnauthorizedAccess");
        _;
    }

    modifier etherverseOrGameDev() {
        require(msg.sender == etherverse || msg.sender == user, "UnauthorizedAccess");
        _;
    }

    modifier onlyGameDev() {
        require(msg.sender == user, "UnauthorizedAccess");
        _;
    }

    constructor(
        address _etherverse,
        address _owner,
        address _usdcToken,
        address _upgrade,
        uint256 _marketFee,
        uint256 _etherverseFee,
        string memory _name
    ) EtherverseUser(_etherverse, _owner, _etherverseFee) {
        name = _name;
        // "Game Name";
        USDC = IERC20(_usdcToken);
        // IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        marketFee = _marketFee;
        // 4269 = 42.69%
        upgradeAddress = _upgrade;
    }

    function createOrder(address _nft, uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_nft != address(0), "Invalid Address");
        IERC721 nft = IERC721(_nft);
        require(
            nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(nft.ownerOf(_tokenId), address(this)),
            "Contract not approved to transfer NFT"
        );

        orders[orderCount] = Order(_nft, _tokenId, _price - marketFee, marketFee, _price, 0);
        emit OrderCreated(orderCount, msg.sender, block.timestamp);
        orderCount++;
    }

    function executeOrder(uint256 _orderId) external nonReentrant {
        Order memory order = orders[_orderId];
        require(order.orderCompleted == 0, "Order already completed");

        IERC721 nft = IERC721(order.nft);
        address nftOwner = nft.ownerOf(order.tokenId);

        if (order.fee != 0) {
            USDC.safeTransferFrom(msg.sender, address(this), order.fee);
        }
        USDC.safeTransferFrom(msg.sender, nftOwner, order.price);
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

    function setUpgradeModule(address _upgrade) external onlyEtherverse {
        upgradeAddress = _upgrade;
    }

    function setUpgradePrice(address _nft, uint256 _price) external etherverseOrGameDev {
        IRPGV1(_nft).setUpgradePrice(_price);
    }

    function mint(address _nft, address to, bytes memory authorizationParams) external {
        IRPGV1(_nft).mint(to, authorizationParams);
    }

    function freeUpgrade(address _nft, uint256 tokenId) external {
        IRPGV1(_nft).freeUpgrade(tokenId);
    }

    function paidUpgrade(address _nft, uint256 tokenId, bytes memory authorizationParams) external {
        IRPGV1(_nft).paidUpgrade(tokenId, authorizationParams);
    }

    function nextUpgrade(address _nft, uint256 tokenId, Upgrade.Type _type) external view {
        IRPGV1(_nft).nextUpgrade(tokenId, _type);
    }

    function nextUpgradePrice(address _nft, uint256 tokenId) external view {
        IRPGV1(_nft).nextUpgradePrice(tokenId);
    }

    function resetUpgradesForNFT(address _nft, uint256 tokenId, address rewardNFT) external nonReentrant onlyGameDev {
        address tokenOwner = IRPGV1(_nft).getOwner(tokenId);
        USDC.safeIncreaseAllowance(_nft, IRPGV1(_nft).mintPrice());
        uint256 rewardToken = IRPGV1(rewardNFT).mint(address(this), "");
        IRPGV1(rewardNFT).transferFrom(address(this), tokenOwner, rewardToken);

        IRPGV1(_nft).resetUpgrades(tokenId);
    }

    function resetUpgradesForUSDC(address _nft, uint256 tokenId, uint256 amount) external nonReentrant onlyGameDev {
        address tokenOwner = IRPGV1(_nft).getOwner(tokenId);
        require(amount > IRPGV1(_nft).mintPrice(), "Reward amount is too low");
        USDC.safeTransfer(tokenOwner, amount);
        IRPGV1(_nft).resetUpgrades(tokenId);
    }
}
