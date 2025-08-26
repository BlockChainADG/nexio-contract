// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract LoanPool is Ownable, EIP712, ReentrancyGuard, Nonces {
    address public signAdmin;
    address public feeAddress;
    uint256 public swapFeeRate;
    uint256 public loanFeeRate;
    uint256 public denominator = 10000;
    bytes32 public constant ML_TYPEHASH =
        keccak256(
            "MortgageAndLoanTransaction(address pledgeToken,uint256 tokenId,uint256 pledgeAmount,address loanToken,uint256 loanAmount,address user,uint256 userNonce,uint256 expTime)"
        );
    bytes32 public constant SWAP_TYPEHASH =
        keccak256(
            "SwapTransaction(address useToken,uint256 useAmount,address receiveToken,uint256 receiveAmount,uint256 expTime)"
        );
    bytes32 public constant BORROW_TYPEHASH =
        keccak256(
            "BorrowTransaction(uint256 positionId,address loanToken,uint256 loanAmount,address user,uint256 userNonce,uint256 expTime)"
        );
    bytes32 public constant PLEDGE_TYPEHASH =
        keccak256(
            "PledgeTransaction(uint256 positionId,address pledgeToken,uint256 tokenId,uint256 pledgeAmount,address user,uint256 userNonce,uint256 expTime)"
        );
    bytes32 public constant REPAY_TYPEHASH =
        keccak256(
            "RepayTransaction(uint256 positionId,address repayToken,uint256 repayAmount,address user,uint256 userNonce,uint256 expTime)"
        );
    bytes32 public constant REDEEM_TYPEHASH =
        keccak256(
            "RedeemTransaction(uint256 positionId,address redeemToken,uint256 tokenId,uint256 redeemAmount,address user,uint256 userNonce,uint256 expTime)"
        );

    struct MortgageAndLoanTransaction {
        address pledgeToken;
        uint256 tokenId;
        uint256 pledgeAmount;
        address loanToken;
        uint256 loanAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    struct SwapTransaction {
        address useToken;
        uint256 useAmount;
        address receiveToken;
        uint256 receiveAmount;
        uint256 expTime;
    }

    struct BorrowTransaction {
        uint256 positionId;
        address loanToken;
        uint256 loanAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    struct PledgeTransaction {
        uint256 positionId;
        address pledgeToken;
        uint256 tokenId;
        uint256 pledgeAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    struct RepayTransaction {
        uint256 positionId;
        address repayToken;
        uint256 repayAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    struct RedeemTransaction {
        uint256 positionId;
        address redeemToken;
        uint256 tokenId;
        uint256 redeemAmount;
        address user;
        uint256 userNonce;
        uint256 expTime;
    }

    event SwapToken(
        address indexed user,
        address useToken,
        address receiveToken,
        uint256 useAmount,
        uint256 receiveAmount,
        uint256 timestamp
    );

    event MortgageAndLoan(
        address indexed user,
        address pledgeToken,
        uint256 tokenId,
        uint256 pledgeAmount,
        address loanToken,
        uint256 loanAmount,
        uint256 userNonce,
        uint256 timestamp
    );

    event Borrow(
        address user,
        uint256 positionId,
        address loanToken,
        uint256 loanAmount,
        uint256 userNonce,
        uint256 timestamp
    );

    event Pledge(
        address user,
        uint256 positionId,
        address pledgeToken,
        uint256 tokenId,
        uint256 pledgeAmount,
        uint256 userNonce,
        uint256 timestamp
    );

    event Repay(
        address user,
        uint256 positionId,
        address repayToken,
        uint256 repayAmount,
        uint256 userNonce,
        uint256 timestamp
    );

    event Redeem(
        address user,
        uint256 positionId,
        address redeemToken,
        uint256 tokenId,
        uint256 redeemAmount,
        uint256 userNonce,
        uint256 timestamp
    );

    event LiqPosition(
        address indexed user,
        uint256 indexed positionId,
        address token,
        uint256 tokenId,
        uint256 amount
    );

    error SignAdminError(address signAdmin);

    constructor(address owner) Ownable(owner) EIP712("NEXIO", "1.0.0") {}

    /**
     * @dev Throws if called by any account other than the signAdmin.
     */
    modifier onlySignAdmin() {
        if (_msgSender() != signAdmin) {
            revert SignAdminError(_msgSender());
        }
        _;
    }

    function mortgageAndLoan(
        address pledgeToken,
        uint256 tokenId,
        uint256 pledgeAmount,
        address loanToken,
        uint256 loanAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        MortgageAndLoanTransaction memory txData = MortgageAndLoanTransaction(
            pledgeToken,
            tokenId,
            pledgeAmount,
            loanToken,
            loanAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforeMortgage(txData, signature);
        IERC1155(pledgeToken).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId,
            pledgeAmount,
            ""
        );
        uint256 receiveAmount = loanAmount;
        uint256 feeAmount = 0;
        if (loanFeeRate > 0) {
            feeAmount = (loanAmount * loanFeeRate) / denominator;
            receiveAmount -= feeAmount;
            IERC20(loanToken).transfer(feeAddress, feeAmount);
        }
        IERC20(loanToken).transfer(_msgSender(), receiveAmount);
        emit MortgageAndLoan(
            _msgSender(),
            pledgeToken,
            tokenId,
            pledgeAmount,
            loanToken,
            loanAmount,
            userNonce,
            block.timestamp
        );
    }

    function _beforeMortgage(
        MortgageAndLoanTransaction memory txData,
        bytes memory signature
    ) private {
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(txData.user, txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                ML_TYPEHASH,
                txData.pledgeToken,
                txData.tokenId,
                txData.pledgeAmount,
                txData.loanToken,
                txData.loanAmount,
                txData.user,
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        require(
            IERC1155(txData.pledgeToken).isApprovedForAll(
                _msgSender(),
                address(this)
            ) == true,
            "The collateral is not authorized"
        );
        require(
            IERC1155(txData.pledgeToken).balanceOf(
                _msgSender(),
                txData.tokenId
            ) >= txData.pledgeAmount,
            "Insufficient user balance"
        );
        require(
            IERC20(txData.loanToken).balanceOf(address(this)) >=
                txData.loanAmount,
            "Insufficient contract balance"
        );
    }

    function addBorrow(
        uint256 positionId,
        address loanToken,
        uint256 loanAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        BorrowTransaction memory txData = BorrowTransaction(
            positionId,
            loanToken,
            loanAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforeBorrow(txData, signature);
        uint256 receiveAmount = loanAmount;
        uint256 feeAmount = 0;
        if (loanFeeRate > 0) {
            feeAmount = (loanAmount * loanFeeRate) / denominator;
            receiveAmount -= feeAmount;
            IERC20(loanToken).transfer(feeAddress, feeAmount);
        }
        IERC20(loanToken).transfer(_msgSender(), receiveAmount);
        emit Borrow(
            _msgSender(),
            positionId,
            loanToken,
            loanAmount,
            userNonce,
            block.timestamp
        );
    }

    function _beforeBorrow(
        BorrowTransaction memory txData,
        bytes memory signature
    ) private {
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                BORROW_TYPEHASH,
                txData.positionId,
                txData.loanToken,
                txData.loanAmount,
                txData.user,
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        require(
            IERC20(txData.loanToken).balanceOf(address(this)) >=
                txData.loanAmount,
            "Insufficient contract balance"
        );
    }

    function addPledge(
        uint256 positionId,
        address pledgeToken,
        uint256 tokenId,
        uint256 pledgeAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        PledgeTransaction memory txData = PledgeTransaction(
            positionId,
            pledgeToken,
            tokenId,
            pledgeAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforePledge(txData, signature);
        IERC1155(pledgeToken).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId,
            pledgeAmount,
            ""
        );
        emit Pledge(
            _msgSender(),
            positionId,
            pledgeToken,
            tokenId,
            pledgeAmount,
            userNonce,
            block.timestamp
        );
    }

    function _beforePledge(
        PledgeTransaction memory txData,
        bytes memory signature
    ) private {
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                PLEDGE_TYPEHASH,
                txData.positionId,
                txData.pledgeToken,
                txData.tokenId,
                txData.pledgeAmount,
                txData.user,
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        require(
            IERC1155(txData.pledgeToken).isApprovedForAll(
                _msgSender(),
                address(this)
            ) == true,
            "The collateral is not authorized"
        );
        require(
            IERC1155(txData.pledgeToken).balanceOf(
                _msgSender(),
                txData.tokenId
            ) >= txData.pledgeAmount,
            "Insufficient user balance"
        );
    }

    function repay(
        uint256 positionId,
        address repayToken,
        uint256 repayAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        RepayTransaction memory txData = RepayTransaction(
            positionId,
            repayToken,
            repayAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _boforeRepay(txData, signature);
        IERC20(repayToken).transferFrom(
            _msgSender(),
            address(this),
            repayAmount
        );
        emit Repay(
            _msgSender(),
            positionId,
            repayToken,
            repayAmount,
            userNonce,
            block.timestamp
        );
    }

    function _boforeRepay(
        RepayTransaction memory txData,
        bytes memory signature
    ) private {
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                REPAY_TYPEHASH,
                txData.positionId,
                txData.repayToken,
                txData.repayAmount,
                txData.user,
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        require(
            IERC20(txData.repayToken).allowance(_msgSender(), address(this)) >=
                txData.repayAmount,
            "Insufficient authorization limit"
        );
        require(
            IERC20(txData.repayToken).balanceOf(_msgSender()) >=
                txData.repayAmount,
            "Insufficient user balance"
        );
    }

    function redeem(
        uint256 positionId,
        address redeemToken,
        uint256 tokenId,
        uint256 redeemAmount,
        uint256 userNonce,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        RedeemTransaction memory txData = RedeemTransaction(
            positionId,
            redeemToken,
            tokenId,
            redeemAmount,
            _msgSender(),
            userNonce,
            expTime
        );
        _beforeRedeem(txData, signature);
        IERC1155(redeemToken).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            redeemAmount,
            ""
        );
        emit Redeem(
            _msgSender(),
            positionId,
            redeemToken,
            tokenId,
            redeemAmount,
            userNonce,
            block.timestamp
        );
    }

    function _beforeRedeem(
        RedeemTransaction memory txData,
        bytes memory signature
    ) private {
        require(txData.expTime >= block.timestamp, "Signature has expired");
        _useCheckedNonce(_msgSender(), txData.userNonce);
        bytes32 structHash = keccak256(
            abi.encode(
                REDEEM_TYPEHASH,
                txData.positionId,
                txData.redeemToken,
                txData.tokenId,
                txData.redeemAmount,
                txData.user,
                txData.userNonce,
                txData.expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        require(
            IERC1155(txData.redeemToken).balanceOf(
                address(this),
                txData.tokenId
            ) >= txData.redeemAmount,
            "Insufficient contract balance"
        );
    }

    function swapToken(
        address token0,
        address token1,
        uint256 swapAmount,
        uint256 receiveAmount,
        uint256 expTime,
        bytes memory signature
    ) external nonReentrant {
        require(
            IERC20(token0).allowance(_msgSender(), address(this)) >= swapAmount,
            "Insufficient authorization limit"
        );
        require(
            IERC20(token1).balanceOf(address(this)) >= receiveAmount,
            "Insufficient contract balance"
        );
        bytes32 structHash = keccak256(
            abi.encode(
                SWAP_TYPEHASH,
                token0,
                swapAmount,
                token1,
                receiveAmount,
                expTime
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(digest, signature) == signAdmin,
            "signature error"
        );
        uint256 feeAmount = 0;
        if (swapFeeRate > 0) {
            feeAmount = (receiveAmount * swapFeeRate) / denominator;
        }
        IERC20(token0).transferFrom(_msgSender(), address(this), swapAmount);
        IERC20(token1).transfer(_msgSender(), receiveAmount - feeAmount);
        if (feeAmount > 0) {
            IERC20(token1).transfer(feeAddress, feeAmount);
        }
        emit SwapToken(
            _msgSender(),
            token0,
            token1,
            swapAmount,
            receiveAmount,
            block.timestamp
        );
    }

    function liqPosition(
        uint256 positionId,
        address token,
        uint256 tokenId,
        uint256 amount
    ) external onlySignAdmin {
        require(amount > 0, "The quantity needs to be greater than 0");
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
        emit LiqPosition(_msgSender(), positionId, token, tokenId, amount);
    }

    function setLoanFeeRate(uint256 loanFeeRate_) external onlyOwner {
        require(
            loanFeeRate_ >= 0 && loanFeeRate_ < 10000,
            "The range of handling fees is incorrect"
        );
        loanFeeRate = loanFeeRate_;
    }

    function setSwapFeeRate(uint256 swapFeeRate_) external onlyOwner {
        require(
            swapFeeRate_ >= 0 && swapFeeRate_ < 10000,
            "The range of handling fees is incorrect"
        );
        swapFeeRate = swapFeeRate_;
    }

    function setFeeAddress(address feeAddress_) external onlyOwner {
        require(feeAddress_ != address(0), "can not zear address");
        feeAddress = feeAddress_;
    }

    function setSignAdmin(address signAdmin_) external onlyOwner {
        require(signAdmin_ != address(0), "can not zear address");
        signAdmin = signAdmin_;
    }

    function takeToken(address token, uint amount) external onlyOwner {
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
        uint amount
    ) external onlyOwner {
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

    receive() external payable {}

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
}
