/**
 *
 *
    Swamp Cash ($CASH) on eth
    https://swamp.cash

    Contract features:
    100,000,000 tokens
    3% buy tax in ETH sent to community, marketing & developer
    16% launch sell tax in ETH sent to community, marketing, & developer
    Function to reduce taxes to 3/3
    Function to remove taxes
    Removable anti-whale restrictions of max transaction & max wallet
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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

// pragma solidity >=0.6.2;
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

// import './IUniswapV2Router01.sol';
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

contract Cash is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    string public exchangeLink = "https://app.uniswap.or/swap";
    string public websiteLink = "https://swamp.cash";

    address public communityWallet;
    address public marketingWallet;
    address public developerWallet;

    bool public tradable = false;
    bool public swappable = false;
    bool private swapping;
    uint256 public swapTokenAmount;

    bool public restrictions = true;
    uint256 public restrictMaxTransaction;
    uint256 public restrictMaxWallet;

    bool public taxation = true;
    bool public taxLopsided = true;

    uint256 public totalBuyTax;
    uint256 public totalSellTax;
    uint256 private communityTax;
    uint256 private marketingTax;
    uint256 private developerTax;

    uint256 public totalLopsidedSellTax;
    uint256 private communityLopsidedSellTax;
    uint256 private marketingLopsidedSellTax;
    uint256 private developerLopsidedSellTax;

    uint256 private communityTokens;
    uint256 private marketingTokens;
    uint256 private developerTokens;

    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event communityWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event developerWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("Swamp Cash", "CASH") Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(
            0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 100_000_000 ether;

        swapTokenAmount = totalSupply / 2000; // 0.05% of total supply (50,000 tokens)

        restrictMaxTransaction = totalSupply / 100; // 1% of total supply (1,000,000 tokens)
        restrictMaxWallet = totalSupply / 20; // 5% of total supply (5,000,000 tokens)

        communityTax = 1;
        marketingTax = 1;
        developerTax = 1;
        totalBuyTax = communityTax + marketingTax + developerTax;
        totalSellTax = communityTax + marketingTax + developerTax;

        communityLopsidedSellTax = 6;
        marketingLopsidedSellTax = 6;
        developerLopsidedSellTax = 4;
        totalLopsidedSellTax =
            communityLopsidedSellTax +
            marketingLopsidedSellTax +
            developerLopsidedSellTax;

        communityWallet = address(0xC6aa2f0FF6b8563EA418ec2558890D6027413699); // Community Funds
        marketingWallet = address(0xC6aa2f0FF6b8563EA418ec2558890D6027413699); // Marketing Funds
        developerWallet = address(0xA6d26E99660de4974B8994eCF75dcD4Cf34951B6); // Developer Funds

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
     * sets swappable to true, enabling automatic swaps once swapTokenAmount is reached
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
        swappable = true;
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
     * @dev Updates the threshold at which the tokens in the contract are automatically swapped for ETH
     */
    function updateSwapTokenAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokenAmount = newAmount;
        return true;
    }

    /**
     * @dev Updates the communityWallet address
     */
    function updateCommunityWallet(
        address _communityWallet
    ) external onlyOwner {
        require(_communityWallet != address(0), "ERC20: Address 0");
        address oldWallet = communityWallet;
        communityWallet = _communityWallet;
        emit communityWalletUpdated(communityWallet, oldWallet);
    }

    /**
     * @dev Updates the marketingWallet address
     */
    function updateMarketingWallet(
        address _marketingWallet
    ) external onlyOwner {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit marketingWalletUpdated(marketingWallet, oldWallet);
    }

    /**
     * @dev Updates the developerWallet address
     */
    // function updateDeveloperWallet(
    //     address _developerWallet
    // ) external onlyOwner {
    //     require(_developerWallet != address(0), "ERC20: Address 0");
    //     address oldWallet = developerWallet;
    //     developerWallet = _developerWallet;
    //     emit developerWalletUpdated(developerWallet, oldWallet);
    // }

    /**
     * @dev removes the max transaction and max wallet restrictions
     * this cannot be reversed
     */
    function removeRestrictions() external onlyOwner {
        restrictions = false;
    }

    /**
     * @dev Resets the tax to 3% buy and 16% sell
     */
    function resetTax() external onlyOwner {
        taxation = true;
        taxLopsided = true;
    }

    /**
     * @dev Sets the sell tax to 3%
     */
    function reduceSellTax() external onlyOwner {
        taxLopsided = false;
    }

    /**
     * @dev Sets the buy and sell fees to 0%
     */
    function removeTax() external onlyOwner {
        taxation = false;
    }

    /**
     * @dev Sends any remaining ETH in the contract that wasn't automatically swapped to the owner
     */
    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    /**
     * @dev Sends any remaining tokens in the contract to the owner
     */
    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    /**
     * @dev stores the address of the automated market maker pair
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
            to != deadAddress &&
            !swapping
        ) {
            if (!tradable) {
                require(
                    from == owner() ||
                        from == address(this) ||
                        from == deadAddress ||
                        from == communityWallet ||
                        from == marketingWallet ||
                        from == developerWallet ||
                        to == owner() ||
                        to == address(this) ||
                        to == deadAddress ||
                        to == communityWallet ||
                        to == marketingWallet ||
                        to == developerWallet,
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
                    to != communityWallet &&
                    to != marketingWallet &&
                    to != developerWallet &&
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
                    from != communityWallet &&
                    from != marketingWallet &&
                    from != developerWallet &&
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
                to != communityWallet &&
                to != marketingWallet &&
                to != developerWallet &&
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

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokenAmount;

        if (
            canSwap &&
            swappable &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            from != address(this) &&
            from != deadAddress &&
            from != communityWallet &&
            from != marketingWallet &&
            from != developerWallet &&
            to != owner() &&
            to != address(this) &&
            to != deadAddress &&
            to != communityWallet &&
            to != marketingWallet &&
            to != developerWallet
        ) {
            swapping = true;

            distributeTax();

            swapping = false;
        }

        bool taxed = !swapping;

        if (
            from == owner() ||
            from == address(this) ||
            from == deadAddress ||
            from == communityWallet ||
            from == marketingWallet ||
            from == developerWallet ||
            to == owner() ||
            to == address(this) ||
            to == deadAddress ||
            to == communityWallet ||
            to == marketingWallet ||
            to == developerWallet
        ) {
            taxed = false;
        }

        uint256 fees = 0;
        uint256 amountToTransfer = amount;

        if (taxed) {
            // Collect Sell Tax
            if (automatedMarketMakerPairs[to] && taxation) {
                if (taxLopsided) {
                    fees = (amount * totalLopsidedSellTax) / 100;
                    communityTokens +=
                        (fees * communityLopsidedSellTax) /
                        totalLopsidedSellTax;
                    marketingTokens +=
                        (fees * marketingLopsidedSellTax) /
                        totalLopsidedSellTax;
                    developerTokens +=
                        (fees * developerLopsidedSellTax) /
                        totalLopsidedSellTax;
                } else {
                    fees = (amount * totalSellTax) / 100;
                    communityTokens += (fees * communityTax) / totalSellTax;
                    marketingTokens += (fees * marketingTax) / totalSellTax;
                    developerTokens += (fees * developerTax) / totalSellTax;
                }
            }
            // Collect Buy Tax
            else if (automatedMarketMakerPairs[from] && taxation) {
                fees = (amount * totalBuyTax) / 100;
                communityTokens += (fees * communityTax) / totalBuyTax;
                marketingTokens += (fees * marketingTax) / totalBuyTax;
                developerTokens += (fees * developerTax) / totalBuyTax;
            }

            if (fees > 0) {
                super._update(from, address(this), fees);
            }

            amountToTransfer -= fees;
        }

        super._update(from, to, amountToTransfer);
    }

    /**
     * @dev Helper function that swaps tokens in the contract for ETH
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Helper function that sends the ETH from the contract to the communityWallet, marketingWallet & developerWallet
     */
    function distributeTax() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = communityTokens +
            marketingTokens +
            developerTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokenAmount * 20) {
            contractBalance = swapTokenAmount * 20;
        }

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance;

        uint256 ethForCommunity = (ethBalance * communityTokens) /
            totalTokensToSwap;
        uint256 ethForMarketing = (ethBalance * marketingTokens) /
            totalTokensToSwap;

        communityTokens = 0;
        marketingTokens = 0;
        developerTokens = 0;

        (success, ) = address(communityWallet).call{value: ethForCommunity}("");
        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");
        (success, ) = address(developerWallet).call{
            value: address(this).balance
        }("");
    }
}
