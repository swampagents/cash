/**
 *
 *
    Swamp Cash ($CASH) on eth
    https://swamp.cash

    Contract features:
    100,000,000 tokens
    Removable anti-whale restrictions of max transaction & max wallet
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Cash is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public uniswapV4Pair;
    address public constant deadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    string public exchangeLink = "https://app.uniswap.or/swap";
    string public websiteLink = "https://swamp.cash";

    bool public tradable = false;

    bool public restrictions = true;
    uint256 public restrictMaxTransaction;
    uint256 public restrictMaxWallet;

    mapping(address => bool) private automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("Swamp Cash", "CASH") Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(
            0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 100_000_000 ether;

        restrictMaxTransaction = totalSupply / 100; // 1% of total supply (1,000,000 tokens)
        restrictMaxWallet = totalSupply / 20; // 5% of total supply (5,000,000 tokens)

        _mint(address(this), totalSupply);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    receive() external payable {}

    /**
     * @dev Enables trading, creates a uniswap pair and adds liquidity using the tokens in the contract.
     *
     * sets tradable to true, it can never be set to false after that
     * stores uniswap pair address in uniswapV2Pair
     */
    function enableTrading() external onlyOwner {
        require(!tradable, "Trading already enabled.");

        uint256 tokensInWallet = balanceOf(address(this));
        uint256 tokensToAdd = (tokensInWallet * 100) / 100; // 100% of tokens in contract go to Liquidity Pool to be paired with ETH in contract

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensToAdd,
            0,
            0,
            owner(),
            block.timestamp
        );

        tradable = true;
    }

    /**
     * @dev Updates the exchangeLink string with a new value
     */
    function updateExchangeLink(string calldata newLink) external onlyOwner {
        exchangeLink = newLink;
    }

    /**
     * @dev Updates the websiteLink string with a new value
     */
    function updateWebsiteLink(string calldata newLink) external onlyOwner {
        websiteLink = newLink;
    }

    /**
     * @dev Updates the uniswapV4Pair string with a new value
     */
    function updateuniswapV4Pair(string calldata v4Pair) external onlyOwner {
        uniswapV4Pair = v4Pair;
    }

    /**
     * @dev Removes the max transaction and max wallet restrictions
     * this cannot be reversed
     */
    function removeRestrictions() external onlyOwner {
        restrictions = false;
    }

    /**
     * @dev Withdraws any accident ETH sent to the contract
     */
    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    /**
     * @dev Withdraws any remaining tokens in the contract to the owner
     */
    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    /**
     * @dev Contract stores the address of the automated market maker pair on creatioon of v2 pool
     */
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._update(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress
        ) {
            if (!tradable) {
                require(
                    from == owner() ||
                        from == address(this) ||
                        from == deadAddress ||
                        to == owner() ||
                        to == address(this),
                    "ERC20: Token Trading Not Enabled. Be Patient Anon."
                );
            }

            //when buy
            if (automatedMarketMakerPairs[from]) {
                if (
                    to != owner() &&
                    to != address(this) &&
                    to != deadAddress &&
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    if (restrictions) {
                        require(
                            amount <= restrictMaxTransaction,
                            "ERC20: Max Transaction Exceeded"
                        );
                        require(
                            amount + balanceOf(to) <= restrictMaxWallet,
                            "ERC20: Max Wallet Exceeded"
                        );
                    }
                }
            }
            //when sell
            else if (automatedMarketMakerPairs[to]) {
                if (
                    from != owner() &&
                    from != address(this) &&
                    from != deadAddress &&
                    from != address(uniswapV2Router) &&
                    from != address(uniswapV2Pair)
                ) {
                    if (restrictions) {
                        require(
                            amount <= restrictMaxTransaction,
                            "ERC20: Max Transaction Exceeded"
                        );
                    }
                }
            } else if (
                to != owner() &&
                to != address(this) &&
                to != deadAddress &&
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair)
            ) {
                if (restrictions) {
                    require(
                        amount + balanceOf(to) <= restrictMaxWallet,
                        "ERC20: Max Wallet Exceeded"
                    );
                }
            }
        }

        super._update(from, to, amount);
    }
}

// OpenZeppelin Contracts v5.0.2 (utils/Context.sol)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// OpenZeppelin Contracts v5.0.2 (access/Ownable.sol)
abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts v5.0.2 (token/ERC20/IERC20.sol)
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// OpenZeppelin Contracts v5.0.2 (token/ERC20/extensions/IERC20Metadata.sol)
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v5.0.2 (token/ERC20/ERC20.sol)
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 value
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert("ERC20: transfer from the zero address");
        }
        if (to == address(0)) {
            revert("ERC20: transfer to the zero address");
        }
        _update(from, to, value);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert("ERC20: transfer amount exceeds balance");
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }
        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert("ERC20: mint to the zero address");
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert("ERC20: burn from the zero address");
        }
        _update(account, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert("ERC20: approve from the zero address");
        }
        if (spender == address(0)) {
            revert("ERC20: approve to the zero address");
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert("ERC20: insufficient allowance");
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// Uniswap Contracts v2 (contracts/IUniswapV2Router01.sol)
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// Uniswap Contracts v2 (contracts/IUniswapV2Router02.sol)
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
