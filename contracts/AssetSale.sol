// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC-721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * @dev Mint NFT to address  return tokenID.
     *
     * Requirements:
     *
     * - `to` must exist and not zear address
     */
    function mint(address to, uint256 amount) external;
}

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

contract AssetSale is Ownable, ReentrancyGuard, Nonces, EIP712 {
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256(
            "ClaimTransaction(uint256 poolId,address token,address to,uint256 amount,uint256 nonces,uint256 deadline)"
        );
    bytes32 public constant BUY_TYPEHASH =
        keccak256(
            "BuyTransaction(uint256 poolId,address buyer,uint256 amount)"
        );

    struct Pool {
        address tokenAddress; //Issued token contracts
        uint256 issuanceQuota; //Issuance quota
        address acceptAddress; //Receiving address
        address paymentToken; //pay token
        uint256 salePrice; //sale price
        uint256 deadline; //end time
        uint256 minBuy;
        uint256 maxHolder;
        uint256 tokenId; //NFT1155 use default:0
        uint8 tokenType; //0-BEP20 1-BEP721 2-BEP1155
        bool isActive; // is active
        uint8 feeRate;
        address feeAddress;
    }

    struct ClaimTransaction {
        uint256 poolId;
        address token;
        address to;
        uint256 amount;
        uint256 nonces;
        uint256 deadline;
    }

    struct BuyTransaction {
        uint256 poolId;
        address buyer;
        uint256 amount;
    }

    uint256 public poolId = 10000;
    mapping(uint => Pool) public _pools;
    mapping(uint => mapping(address => uint)) public userHoldQuota;
    address public signAdmin;

    event BuyNft(
        uint256 indexed _poolId,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount
    );

    event Claim(
        uint256 indexed poolId,
        address indexed token,
        address indexed to,
        uint256 amount,
        uint256 nonces,
        uint256 deadline
    );

    constructor(
        address initialOwner
    ) Ownable(initialOwner) EIP712("NEXIO", "1.0.0") {}

    function createPool(
        address _tokenAddress,
        uint256 _issuanceQuota,
        address _acceptAddress,
        address _paymentToken,
        uint256 _salePrice,
        uint256 _deadline,
        uint256 _minBuy,
        uint256 _maxHolder,
        uint256 _tokenId,
        TokenType _tokenType,
        bool _isActive,
        uint8 _feeRate,
        address _feeAddress
    ) external onlyOwner returns (uint256) {
        _validatePoolParams(
            _tokenType,
            _salePrice,
            _issuanceQuota,
            _acceptAddress,
            _minBuy,
            _maxHolder,
            _feeRate,
            _feeAddress
        );
        poolId++;
        _pools[poolId] = Pool(
            _tokenAddress,
            _issuanceQuota,
            _acceptAddress,
            _paymentToken,
            _salePrice,
            _deadline,
            _minBuy,
            _maxHolder,
            _tokenId,
            uint8(_tokenType),
            _isActive,
            _feeRate,
            _feeAddress
        );
        return poolId;
    }

    function setPoolStatus(uint256 _poolId, bool _isActive) external onlyOwner {
        require(_poolId > 10000 && _poolId <= poolId, "Invalid pool ID");
        _pools[_poolId].isActive = _isActive;
    }

    function setPoolFee(
        uint256 _poolId,
        uint8 _feeRate,
        address _feeAddress
    ) external onlyOwner {
        require(_poolId > 10000 && _poolId <= poolId, "Invalid pool ID");
        require(_feeRate < 10000, "Fee Rate must be lt 10000");
        require(_feeAddress != address(0), "Fee address cat not be zear");
        _pools[_poolId].feeRate = _feeRate;
        _pools[_poolId].feeAddress = _feeAddress;
    }

    function buy(
        uint _poolId,
        uint amount,
        bytes memory signature
    ) external payable nonReentrant returns (bool) {
        require(
            _verifyKyc(_poolId, amount, signature),
            "You are currently not eligible to purchase"
        );
        Pool memory pool = _pools[_poolId];
        _beforeBuy(_poolId, pool, amount);
        unchecked {
            _pools[_poolId].issuanceQuota -= amount;
            userHoldQuota[_poolId][_msgSender()] += amount;
        }
        _acceptPayment(pool, amount);
        _transferTokensToBuyer(pool, amount);
        emit BuyNft(_poolId, _msgSender(), pool.tokenId, amount);
        return true;
    }

    function _verifyKyc(
        uint _poolId,
        uint amount,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(BUY_TYPEHASH, _poolId, _msgSender(), amount)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        return ECDSA.recover(digest, signature) == signAdmin;
    }

    function claim(
        uint256 _poolId,
        address token,
        uint256 amount,
        uint256 nonces,
        uint256 deadline,
        bytes memory signature
    ) external nonReentrant returns (bool) {
        ClaimTransaction memory txData = ClaimTransaction(
            _poolId,
            token,
            _msgSender(),
            amount,
            nonces,
            deadline
        );
        require(
            _verifySigner(txData, signature) == signAdmin,
            "Signature address error"
        );
        require(block.timestamp <= txData.deadline, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.nonces);
        IERC20 claimToken = IERC20(txData.token);
        require(
            claimToken.balanceOf(address(this)) >= txData.amount,
            "Insufficient contract balance"
        );
        claimToken.transfer(_msgSender(), txData.amount);
        emit Claim(
            _poolId,
            txData.token,
            _msgSender(),
            txData.amount,
            txData.nonces,
            txData.deadline
        );
        return true;
    }

    function _transferTokensToBuyer(Pool memory pool, uint256 amount) private {
        if (pool.tokenType == uint8(TokenType.ERC20)) {
            IERC20 saleToken = IERC20(pool.tokenAddress);
            saleToken.transfer(
                _msgSender(),
                amount * 10 ** saleToken.decimals()
            );
        } else if (pool.tokenType == uint8(TokenType.ERC721)) {
            IERC721(pool.tokenAddress).mint(_msgSender(), amount);
        } else {
            IERC1155(pool.tokenAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                pool.tokenId,
                amount,
                ""
            );
        }
    }

    function _acceptPayment(Pool memory pool, uint256 amount) private {
        uint256 totalPrice = pool.salePrice * amount;
        uint256 fee = (totalPrice * pool.feeRate) / 10000;
        uint256 actualAmount = totalPrice - fee;
        if (pool.paymentToken == address(0)) {
            if (fee > 0) payable(pool.feeAddress).transfer(fee);
            payable(pool.acceptAddress).transfer(actualAmount);
        } else {
            IERC20 payToken = IERC20(pool.paymentToken);
            if (fee > 0) {
                payToken.transferFrom(_msgSender(), pool.feeAddress, fee);
            }
            payToken.transferFrom(
                _msgSender(),
                pool.acceptAddress,
                actualAmount
            );
        }
    }

    function _validatePoolParams(
        TokenType _tokenType,
        uint256 _salePrice,
        uint256 _issuanceQuota,
        address _acceptAddress,
        uint256 _minBuy,
        uint256 _maxHolder,
        uint8 _feeRate,
        address _feeAddress
    ) private pure {
        require(uint8(_tokenType) <= 2, "Invalid token type");
        require(_salePrice > 0, "Sale price must be greater than 0");
        require(_issuanceQuota > 0, "Issuance quota must be greater than 0");
        require(_acceptAddress != address(0), "Accept address cannot be zero");
        require(_minBuy > 0 && _maxHolder >= _minBuy, "Invalid buy limits");
        require(_feeRate < 10000, "Fee Rate must be lt 10000");
        require(_feeAddress != address(0), "Fee address cannot be zero");
    }

    function _beforeBuy(
        uint256 _poolId,
        Pool memory pool,
        uint256 amount
    ) private view {
        require(_poolId > 10000 && _poolId <= poolId, "Invalid poolid");
        require(amount > 0, "The purchase quantity must be greater than 0");
        require(pool.isActive == true, "Pool is closed");
        uint256 userUseQuota = userHoldQuota[_poolId][_msgSender()];
        require(
            amount >= pool.minBuy && amount <= pool.issuanceQuota,
            "Insufficient balance in the pool"
        );
        require(
            (userUseQuota + amount) <= pool.maxHolder,
            "Insufficient available purchase limit"
        );
        if (pool.deadline != 0) {
            require(
                block.timestamp <= pool.deadline,
                "The sale time of this asset has ended"
            );
        }
        _checkPayment(pool, amount);
        _checkPoolBalance(pool, amount);
    }

    function _checkPayment(Pool memory pool, uint256 amount) private view {
        uint256 totalPrice = pool.salePrice * amount;
        if (pool.paymentToken == address(0)) {
            require(msg.value == totalPrice, "Incorrect payment price");
        } else {
            IERC20 payToken = IERC20(pool.paymentToken);
            uint approveQuota = payToken.allowance(_msgSender(), address(this));
            require(
                approveQuota >= totalPrice,
                "Insufficient authorization limit"
            );
        }
    }

    function _checkPoolBalance(Pool memory pool, uint amount) private view {
        if (pool.tokenType == uint8(TokenType.ERC20)) {
            IERC20 saleToken = IERC20(pool.tokenAddress);
            uint balance = saleToken.balanceOf(address(this));
            require(
                balance >= amount * 10 ** saleToken.decimals(),
                "Insufficient contract balance"
            );
        }
        if (pool.tokenType == uint8(TokenType.ERC1155)) {
            uint balance = IERC1155(pool.tokenAddress).balanceOf(
                address(this),
                pool.tokenId
            );
            require(balance >= amount, "Insufficient contract balance");
        }
    }

    function _hashTransaction(
        ClaimTransaction memory txData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_TYPEHASH,
                    txData.poolId,
                    txData.token,
                    txData.to,
                    txData.amount,
                    txData.nonces,
                    txData.deadline
                )
            );
    }

    function _verifySigner(
        ClaimTransaction memory txData,
        bytes memory signature
    ) private view returns (address) {
        bytes32 structHash = _hashTransaction(txData);
        bytes32 digest = _hashTypedDataV4(structHash);
        return ECDSA.recover(digest, signature);
    }

    function setSignAdmin(address signAdmin_) public onlyOwner {
        signAdmin = signAdmin_;
    }

    function takeToken(address token, uint amount) public onlyOwner {
        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Insufficient contract balance"
            );
            payable(owner()).transfer(amount);
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "Insufficient contract balance"
            );
            IERC20(token).transfer(owner(), amount);
        }
    }

    function takeNFT(
        address token,
        uint tokenId,
        uint amount,
        uint8 tokenType
    ) public onlyOwner {
        if (tokenType == uint8(TokenType.ERC721)) {
            require(
                IERC721(token).ownerOf(tokenId) == owner(),
                "The contract currently does not have permission for this NFT"
            );
            IERC721(token).safeTransferFrom(address(this), owner(), tokenId);
        } else {
            require(
                IERC1155(token).balanceOf(address(this), tokenId) >= amount,
                "Insufficient contract balance"
            );
            IERC1155(token).safeTransferFrom(
                address(this),
                owner(),
                tokenId,
                amount,
                ""
            );
        }
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}
