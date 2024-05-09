// SPDX-License-Identifier: MIT
// File: contracts/libraries/SafeMath.sol


pragma solidity ^0.8.25;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/interfaces/ERC721.sol


/// @title ERC721 interface implementation
// Sources
// https://eips.ethereum.org/EIPS/eip-721
pragma solidity ^0.8.25;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable is ERC721 {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view returns (uint256);
}

// File: contracts/interfaces/ERC20.sol


/// @title ERC20 interface implementation
// Sources
// https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
pragma solidity ^0.8.25;

interface ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}

// File: contracts/Ownable.sol


pragma solidity ^0.8.25;

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/HotswapBase.sol


pragma solidity ^0.8.25;


contract HotswapBase is Ownable {
    function _transferNative(
        address payable to,
        uint256 amount
    ) internal returns (bool) {
        if (to.send(amount)) {
            emit NativeTransferred(amount, to);
            return true;
        }

        return false;
    }

    event NativeTransferred(uint256 amount, address targetAddr);
}

// File: contracts/HotswapLiquidity.sol


pragma solidity ^0.8.25;






contract HotswapLiquidity is HotswapBase {
    using SafeMath for uint256;

    constructor(address nft, address fft) {
        NFT = nft;
        FFT = fft;

        _fft = ERC20(fft);
        _nft = ERC721Enumerable(nft);
    }

    address public NFT;
    address public FFT;
    address public Controller;

    ERC20 _fft;
    ERC721Enumerable _nft;

    modifier onlyAuthorized() {
        require(msg.sender == _owner || msg.sender == Controller);
        _;
    }

    function withdrawFFT(uint256 amount, address dest) external onlyAuthorized {
        require(_fft.transfer(dest, amount), "Withdrawal failed");
    }

    function withdrawNFT(uint256 amount, address dest) external onlyAuthorized {
        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = 0; i < amount; i++) {
            tokenId = _nft.tokenOfOwnerByIndex(address(this), i);
            _nft.safeTransferFrom(address(this), dest, tokenId, data);
        }
    }

    function setController(address addr) external onlyOwner {
        Controller = addr;
    }
}

// File: contracts/HotswapControllerBase.sol


pragma solidity ^0.8.25;





interface IHotswapController {
    function setCollector(address addr) external;

    function setLiquidity(address addr) external;
}

interface IHotswapLiquidity {
    function setController(address addr) external;

    function withdrawFFT(uint256 amount, address dest) external;

    function withdrawNFT(uint256 amount, address dest) external;
}

contract HotswapControllerBase is Ownable, IHotswapController {
    using SafeMath for uint256;

    address public NFT;
    address public FFT;
    address public _collector;
    address public _liquidity;

    uint256 public _price;

    ERC20 internal _fft;
    ERC721Enumerable internal _nft;

    mapping(address => uint256[]) internal _liquidityByUser;

    Liquid[] public _liquidities;
    uint256 public _fees;

    constructor(address nft, address fft) {
        _collector = msg.sender;
        NFT = nft;
        FFT = fft;

        _fft = ERC20(fft);
        _nft = ERC721Enumerable(nft);
    }

    function _computePrice() internal returns (uint256) {
        uint256 fBalance = _fft.balanceOf(_liquidity);
        uint256 nBalance = _nft.balanceOf(_liquidity);

        // TODO: Consider the decimal points, etc
        if (nBalance != 0) {
            _price = fBalance / nBalance;
        }

        return _price;
    }

    function setCollector(address addr) external onlyOwner {
        _collector = addr;
    }

    function setLiquidity(address addr) external onlyOwner {
        _liquidity = addr;
        _computePrice();
    }

    struct Liquid {
        address depositor;
        uint256 depositedAt;
        uint256 price;
        uint256 nftAlloc;
        uint256 fftAlloc;
        bool claimed;
        uint256 userIndex;
    }

    struct LiquidData {
        address depositor;
        uint256 depositedAt;
        uint256 price;
        uint256 nftAlloc;
        uint256 fftAlloc;
        bool claimed;
    }
}

// File: contracts/HotswapController.sol


/// @title Hotswap Controller
// Sources
pragma solidity ^0.8.25;




contract HotswapController is HotswapControllerBase {
    uint256 public nftLiquidity; // xLiquid
    uint256 public fftLiquidity; // yLiquid

    uint256 private _nftLiquidityCount;
    uint256 private _fftLiquidityCount;

    uint256 private constant FEE_RATIO_BY_TEN_THOUSAND = 5; // 0.05%

    constructor(address nft, address fft) HotswapControllerBase(nft, fft) {}

    event HotswapDeployed(address controllor, address liquidity);

    function getPrice() public returns (uint256) {
        return _computePrice();
    }

    function depositNFT(uint256 amount) external {
        require(
            _liquidity != address(0),
            "Liquidity address is yet to be assigned"
        );

        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = 0; i < amount; i++) {
            tokenId = _nft.tokenOfOwnerByIndex(msg.sender, i);
            _nft.safeTransferFrom(msg.sender, _liquidity, tokenId, data);
        }

        _createLiquid(amount, true);
    }

    function depositFFT(uint256 amount) external {
        bool success = _fft.transferFrom(msg.sender, _liquidity, amount);

        require(success, "Transfer failed");
        _createLiquid(amount, true);
    }

    function _createLiquid(uint256 amount, bool kind) private {
        uint256[] storage userLiquid = _liquidityByUser[msg.sender];
        uint256 index = userLiquid.length;

        uint256 nftAmount = 0;
        uint256 fftAmount = 0;

        if (kind) {
            nftAmount = amount;
        } else {
            fftAmount = amount;
        }

        Liquid memory lq = Liquid(
            msg.sender,
            block.timestamp,
            _price,
            nftAmount,
            fftAmount,
            false,
            userLiquid.length
        );

        if (kind) {
            _nftLiquidityCount++;
        } else {
            _fftLiquidityCount++;
        }

        _liquidities.push(lq);
        userLiquid.push(index);
    }

    function queryLiquid(
        uint256 index
    ) external view returns (LiquidData memory) {
        return queryLiquidbyDepositor(msg.sender, index);
    }

    function queryLiquidbyDepositor(
        address depositor,
        uint256 index
    ) public view returns (LiquidData memory) {
        uint256[] memory indexes = _liquidityByUser[depositor];
        require(index < indexes.length, "Index out of range");

        uint256 n = indexes[index];

        Liquid memory lq = _liquidities[n];

        return
            LiquidData(
                lq.depositor,
                lq.depositedAt,
                lq.price,
                lq.nftAlloc,
                lq.fftAlloc,
                lq.claimed
            );
    }

    function getLiquidityCount(bool isFFT) external view returns (uint256) {
        if (isFFT) {
            return _fftLiquidityCount;
        } else {
            return _nftLiquidityCount;
        }
    }

    function withdrawLiquidity(uint256 index) external {
        address user = msg.sender;
        uint256[] memory userLiquid = _liquidityByUser[user];

        require(index < userLiquid.length, "Index out of range");

        uint256 n = userLiquid[index];
        Liquid memory lq = _liquidities[n];

        uint256 nftAlloc = lq.nftAlloc;
        uint256 fftAlloc = lq.fftAlloc;

        uint256 total = nftAlloc + fftAlloc;
        uint256 nftRatio = total / nftAlloc;
        uint256 fftRatio = total / fftAlloc;

        // TODO: Revist and re-eval
        IHotswapLiquidity liq = IHotswapLiquidity(_liquidity);

        uint256 nftBalance = (nftAlloc / nftRatio) / _price;
        uint256 fftBalance = fftAlloc / fftRatio;

        liq.withdrawNFT(nftBalance, user);
        liq.withdrawFFT(fftBalance, user);

        _removeLiquidity(lq, n);
    }

    function _removeLiquidity(Liquid memory lq, uint256 index) private {
        uint256 userIndex = lq.userIndex;

        Liquid storage last;
        uint256[] storage userLiquids = _liquidityByUser[msg.sender];

        if (_removeItem(userLiquids, userIndex)) {
            last = _liquidities[userLiquids[userIndex]];
            last.userIndex = userIndex;
        }

        if (_removeItem(_liquidities, index)) {
            last = _liquidities[index];

            userIndex = last.userIndex;
            _liquidityByUser[last.depositor][userIndex] = index;
        }
    }

    function _removeItem(
        Liquid[] storage arr,
        uint256 index
    ) internal returns (bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;

        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
    }

    function _removeItem(
        uint256[] storage arr,
        uint256 index
    ) internal returns (bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;

        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
    }

    function _deductFee(uint256 amount) private returns (uint256) {
        uint256 fee = (amount * FEE_RATIO_BY_TEN_THOUSAND) / 10_000;

        uint256 collectorFee = fee / 5;
        uint256 remFee = fee - collectorFee;

        bool success = _fft.transfer(_collector, collectorFee);
        require(success);
        success = _fft.transfer(address(this), remFee);
        require(success);

        _fees += remFee;

        return fee;
    }

    function swapNFT(uint256 amount) external {
        Liquid storage source;
        Liquid storage target;

        uint256[] memory indexes = _liquidityByUser[msg.sender];

        uint256 price = _price;

        uint256 fftAmount = amount * price;

        fftAmount -= _deductFee(fftAmount);
        uint256 nftAmount = fftAmount / price;

        bool success;
        uint256 index;

        uint256 i;
        uint256 j;

        for (j = indexes.length; j > 0 && nftAmount > 0; j--) {
            i = j - 1;
            source = _liquidities[indexes[i]];

            (success, index) = _findSuitableLiquid(false);
            target = _liquidities[index];

            nftAmount = _swapNFTLiquid(source, target, nftAmount, price);
        }

        require(nftAmount == 0, "Insufficient liquidity");
    }

    function swapFFT(uint256 amount) external {
        Liquid storage source;
        Liquid storage target;

        uint256[] memory indexes = _liquidityByUser[msg.sender];
        uint256 price = _price;

        uint256 targetAmount = _deductFee(amount);

        uint256 fftAmount = targetAmount;

        bool success;
        uint256 index;

        uint256 i;
        uint256 j;

        for (j = indexes.length; j > 0 && fftAmount > 0; j--) {
            i = j - 1;
            source = _liquidities[indexes[i]];

            (success, index) = _findSuitableLiquid(true);
            target = _liquidities[index];

            fftAmount = _swapFFTLiquid(source, target, fftAmount, price);
        }

        require(fftAmount == 0, "Insufficient liquidity");
    }

    function _swapNFTLiquid(
        Liquid storage source,
        Liquid storage target,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        uint256 swapAmount;

        if (source.nftAlloc <= targetAmount) {
            swapAmount = source.nftAlloc;
        } else {
            swapAmount = targetAmount;
        }

        source.nftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        source.fftAlloc += swapAmount * price;
        target.nftAlloc += swapAmount;

        return targetAmount;
    }

    function _swapFFTLiquid(
        Liquid storage source,
        Liquid storage target,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        uint256 alloc = source.fftAlloc;

        uint256 swapAmount = alloc <= targetAmount ? alloc : targetAmount;

        source.fftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        source.nftAlloc += swapAmount / price;
        target.fftAlloc += swapAmount;

        return targetAmount;
    }

    function _findSuitableLiquid(
        bool isNFT
    ) private view returns (bool success, uint256 index) {
        Liquid memory liquid;

        uint256 j;

        for (j = _liquidities.length; j > 0 && !success; j--) {
            index = j - 1;

            liquid = _liquidities[index];

            if (!isNFT && liquid.fftAlloc > 0) {
                success = true;
            } else if (isNFT && liquid.nftAlloc > 0) {
                success = true;
            }
        }
    }
}

// File: contracts/HotswapFactory.sol


pragma solidity ^0.8.25;






contract HotswapFactory is HotswapBase {
    address[] controllers;
    address[] liquidities;

    address payable _defaultCollector;
    //; uint256 private constant DEPLOY_FEE = 1e18;
    uint256 private constant DEPLOY_FEE = 1e15;

    constructor() {
        _defaultCollector = payable(msg.sender);
    }

    function setCollector(
        address controllerAddr,
        address addr
    ) external onlyOwner {
        IHotswapController(controllerAddr).setCollector(addr);
    }

    function setFactory(
        address controllerAddr,
        address factoryAddr
    ) external onlyOwner {
        IOwnable(controllerAddr).transferOwnership(factoryAddr);
        address targetAddr;

        // Remove the controller from our records
        for (uint256 i = controllers.length; i > 0; i--) {
            targetAddr = controllers[i - 1];

            if (controllerAddr != targetAddr) {
                break;
            }

            uint256 last = controllers.length - 1;
            if (i != last) {
                controllers[i] = controllers[last];
            }

            controllers.pop();
        }
    }

    function setController(
        address liquidityAddr,
        address addr
    ) external onlyOwner {
        IHotswapLiquidity(liquidityAddr).setController(addr);
    }

    function deployHotswap(address nft, address fft) external payable {
        require(msg.value == DEPLOY_FEE, "Invalid fee amount");

        // TODO: Probably allow default collector to be changable
        if (_defaultCollector != address(0)) {
            _transferNative(_defaultCollector, msg.value);
        }

        HotswapController controller = new HotswapController(nft, fft);
        HotswapLiquidity liquidity = new HotswapLiquidity(nft, fft);

        address controllerAddr = address(controller);
        address liquidityAddr = address(liquidity);

        liquidity.setController(controllerAddr);
        controller.setLiquidity(liquidityAddr);

        controllers.push(controllerAddr);
        liquidities.push(liquidityAddr);

        emit HotswapDeployed(controllerAddr, liquidityAddr);
    }

    function setDefaultCollector(address addr) external {
        _defaultCollector = payable(addr);
    }

    function _removeItem(
        uint256[] storage arr,
        uint256 index
    ) internal returns (bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;

        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
    }

    event HotswapDeployed(address controllor, address liquidity);
}
