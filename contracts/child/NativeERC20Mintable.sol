// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/child/IStateReceiver.sol";
import "./System.sol";

/**
    @title NativeERC20Mintable
    @author Polygon Technology
    @notice Native (mintable) token contract on Polygon V3 / supernet chains
    @dev The contract exposes ERC20-like functions that are compatible with the native token
 */
// solhint-disable reason-string
contract NativeERC20Mintable is Context, Initializable, System, Ownable2Step, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address private _predicate;
    address private _rootToken;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    modifier onlyPredicateOrMinter() {
        require(msg.sender == _predicate || msg.sender == owner(), "NativeERC20: Only predicate or owner can call");

        _;
    }

    /**
     * @dev Sets the values for {predicate}, {name} and {symbol}.
     *
     * The default value of {decimals} is 18.
     *
     * All three of these values are immutable: they can only be set once during
     * initialization.
     */
    function initialize(
        address predicate_,
        address owner_,
        address rootToken_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_
    ) external initializer onlySystemCall {
        require(owner_ != address(0), "NativeERC20: Invalid owner address");
        // slither-disable-next-line missing-zero-check,events-access
        _predicate = predicate_;
        // slither-disable-next-line missing-zero-check
        _rootToken = rootToken_; // root token should be set to zero where no root token exists
        _name = name_;
        _symbol = symbol_;
        // slither-disable-next-line events-maths
        _decimals = decimals_;
        _transferOwnership(owner_);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Mints an amount of tokens to a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to mint the tokens to
     * @param amount Amount of tokens to mint to the account
     * @return bool Returns true if function call is succesful
     */
    function mint(address account, uint256 amount) external onlyPredicateOrMinter returns (bool) {
        _mint(account, amount);

        return true;
    }

    /**
     * @notice Burns an amount of tokens from a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to burn the tokens from
     * @param amount Amount of tokens to burn from the account
     * @return bool Returns true if function call is succesful
     */
    function burn(address account, uint256 amount) external onlyPredicateOrMinter returns (bool) {
        _burn(account, amount);

        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return account.balance;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function predicate() public view virtual returns (address) {
        return _predicate;
    }

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function rootToken() public view virtual returns (address) {
        return _rootToken;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // slither-disable-next-line reentrancy-events,low-level-calls
        (bool success, bytes memory result) = NATIVE_TRANSFER_PRECOMPILE.call(abi.encode(from, to, amount)); // solhint-disable-line avoid-low-level-calls
        require(success && abi.decode(result, (bool)), "PRECOMPILE_CALL_FAILED");

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;

        // slither-disable-next-line reentrancy-events,low-level-calls
        (bool success, bytes memory result) = NATIVE_TRANSFER_PRECOMPILE.call(abi.encode(address(0), account, amount)); // solhint-disable-line avoid-low-level-calls
        require(success && abi.decode(result, (bool)), "PRECOMPILE_CALL_FAILED");

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply -= amount;

        // slither-disable-next-line reentrancy-events,low-level-calls
        (bool success, bytes memory result) = NATIVE_TRANSFER_PRECOMPILE.call(abi.encode(account, address(0), amount)); // solhint-disable-line avoid-low-level-calls
        require(success && abi.decode(result, (bool)), "PRECOMPILE_CALL_FAILED");

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
