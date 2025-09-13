// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IStockRWA {
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

    /**
     * mint method
     * @param to accept address
     * @param amount amount
     */
    function mint(address to, uint256 amount) external;

    /**
     * burn method
     * @param account account
     * @param amount amount
     */
    function burn(address account, uint256 amount) external;

    function pause() external;

    function unpause() external;

    /**
     * @param initialOwner owner
     * @param name name
     * @param symbol  symbol
     */
    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol
    ) external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

contract StockRWAFactory is Ownable, ReentrancyGuard, EIP712, Nonces {
    address[] public stockList;
    mapping(address => bool) stockExists;
    address public signAdmin;
    address public feeAddress;
    address public implementation;
    uint256 public feeRate;
    uint256 public denominator = 10000;

    bytes32 public constant MINT_HASH =
        keccak256(
            "MintTokenTransaction(address costToken,uint256 costAmount,address stockToken,uint256 stockAmount,address user,uint256 userNonce,uint256 expTime)"
        );
    bytes32 public constant BURN_HASH =
        keccak256(
            "BurnTokenTransaction(address stockToken,uint256 stockAmount,address returnToken,uint256 returnAmount,address user,uint256 userNonce,uint256 expTime)"
        );

    struct MintTokenTransaction {
        address costToken;
        uint256 costAmount;
        address stockToken;
        uint256 stockAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    struct BurnTokenTransaction {
        address stockToken;
        uint256 stockAmount;
        address returnToken;
        uint256 returnAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    event TokenMinted(
        address costToken,
        uint256 costAmount,
        address stockToken,
        uint256 stockAmount,
        address user,
        uint256 userNonce,
        uint256 timestamp
    );

    event TokenBurned(
        address stockToken,
        uint256 stockAmount,
        address returnToken,
        uint256 returnAmount,
        address user,
        uint256 userNonce,
        uint256 timestamp
    );

    constructor(
        address owner,
        address implementation_
    ) Ownable(owner) EIP712("NEXIO", "1.0.0") {
        implementation = implementation_;
    }

    //创建代币
    function createToken(
        string memory name,
        string memory symbol
    ) external onlyOwner {
        address newToken = Clones.clone(implementation);
        IStockRWA(newToken).initialize(address(this), name, symbol);
        stockList.push(newToken);
        stockExists[newToken] = true;
    }

    //铸造代币
    function mintToken(
        address costToken,
        uint256 costAmount,
        address stockToken,
        uint256 stockAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        MintTokenTransaction memory txData = MintTokenTransaction(
            costToken,
            costAmount,
            stockToken,
            stockAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforeMintToken(txData, signature);
        //收款
        IStockRWA(costToken).transferFrom(_msgSender(), feeAddress, costAmount);
        IStockRWA(stockToken).mint(_msgSender(), stockAmount);
        emit TokenMinted(
            costToken,
            costAmount,
            stockToken,
            stockAmount,
            _msgSender(),
            userNonce,
            block.timestamp
        );
    }

    function _beforeMintToken(
        MintTokenTransaction memory txData,
        bytes memory signature
    ) private {
        require(stockExists[txData.stockToken], "Token does not exist");
        require(
            txData.costAmount > 0 && txData.stockAmount > 0,
            "quantity is incorrect"
        );
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                MINT_HASH,
                txData.costToken,
                txData.costAmount,
                txData.stockToken,
                txData.stockAmount,
                _msgSender(),
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        //检测用户余额
        require(
            IStockRWA(txData.costToken).allowance(
                _msgSender(),
                address(this)
            ) >= txData.costAmount,
            "Insufficient authorization limit"
        );
        require(
            IStockRWA(txData.costToken).balanceOf(_msgSender()) >=
                txData.costAmount,
            "Insufficient user balance"
        );
    }

    //销毁代币
    function burnToken(
        address stockToken,
        uint256 stockAmount,
        address returnToken,
        uint256 returnAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        BurnTokenTransaction memory txData = BurnTokenTransaction(
            stockToken,
            stockAmount,
            returnToken,
            returnAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforeBurnToken(txData, signature);
        //燃烧代币
        IStockRWA(stockToken).burn(_msgSender(), stockAmount);
        uint256 feeAmount = 0;
        if (feeRate > 0) {
            feeAmount = (returnAmount * feeRate) / denominator;
            IStockRWA(returnToken).transfer(feeAddress, feeAmount);
        }
        IStockRWA(returnToken).transfer(_msgSender(), returnAmount - feeAmount);
        emit TokenBurned(
            stockToken,
            stockAmount,
            returnToken,
            returnAmount,
            _msgSender(),
            userNonce,
            block.timestamp
        );
    }

    function _beforeBurnToken(
        BurnTokenTransaction memory txData,
        bytes memory signature
    ) private {
        require(stockExists[txData.stockToken], "Token does not exist");
        require(stockExists[txData.stockToken], "Token does not exist");
        require(
            txData.returnAmount > 0 && txData.stockAmount > 0,
            "quantity is incorrect"
        );
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                BURN_HASH,
                txData.stockToken,
                txData.stockAmount,
                txData.returnToken,
                txData.returnAmount,
                _msgSender(),
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        //检测用户余额
        require(
            IStockRWA(txData.stockToken).allowance(
                _msgSender(),
                address(this)
            ) >= txData.stockAmount,
            "Insufficient authorization limit"
        );
        require(
            IStockRWA(txData.stockToken).balanceOf(_msgSender()) >=
                txData.stockAmount,
            "Insufficient user balance"
        );
        //检测合约余额
        require(
            IStockRWA(txData.returnToken).balanceOf(address(this)) >=
                txData.returnAmount,
            "Insufficient contract balance"
        );
    }

    //暂停转账
    function pauseToken(address token) external onlyOwner {
        require(token != address(0) && stockExists[token], "token not exists");
        IStockRWA(token).pause();
    }

    //开启转账
    function unPauseToken(address token) external onlyOwner {
        require(token != address(0) && stockExists[token], "token not exists");
        IStockRWA(token).unpause();
    }

    //丢弃权限
    function renounceTokenOwnership(address token) external onlyOwner {
        require(token != address(0) && stockExists[token], "token not exists");
        IStockRWA(token).renounceOwnership();
    }

    //转移代币管理员
    function transferTokenOwnership(
        address token,
        address newOwner
    ) external onlyOwner {
        require(token != address(0) && stockExists[token], "token not exists");
        IStockRWA(token).transferOwnership(newOwner);
    }

    //设置手续费
    function setFeeRate(uint256 feeRate_) external onlyOwner {
        require(
            feeRate_ >= 0 && feeRate_ < 10000,
            "The range of handling fees is incorrect"
        );
        feeRate = feeRate_;
    }

    //设置手续费接受地址
    function setFeeAddress(address feeAddress_) external onlyOwner {
        require(feeAddress_ != address(0), "can not zear address");
        feeAddress = feeAddress_;
    }

    //设置签名管理员
    function setSignAdmin(address signAdmin_) external onlyOwner {
        require(signAdmin_ != address(0), "can not zear address");
        signAdmin = signAdmin_;
    }

    //提取合约里面的代币
    function takeToken(address token, uint amount) external onlyOwner {
        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Insufficient contract balance"
            );
            //提去主币
            payable(owner()).transfer(amount);
        } else {
            require(
                IStockRWA(token).balanceOf(address(this)) >= amount,
                "Insufficient contract balance"
            );
            //提取代币
            IStockRWA(token).transfer(owner(), amount);
        }
    }

    receive() external payable {}
}
