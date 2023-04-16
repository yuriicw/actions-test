// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title CardPaymentCashback types interface
 */
interface ICardPaymentCashbackTypes {
    /// @dev Structure with data of a single cashback operation.
    struct Cashback {
        uint256 lastCashbackNonce; // The nonce of the last cashback operation.
    }
}

/**
 * @title CardPaymentCashback interface
 * @dev The interface of the wrapper contract for the card payment cashback operations.
 */
interface ICardPaymentCashback is ICardPaymentCashbackTypes {
    /**
     * @dev Emitted when the cashback distributor is changed.
     * @param oldDistributor The address of the old cashback distributor contract.
     * @param newDistributor The address of the new cashback distributor contract.
     */
    event SetCashbackDistributor(address oldDistributor, address newDistributor);

    /**
     * @dev Emitted when the cashback rate is changed.
     * @param oldRateInPermil The value of the old cashback rate in permil.
     * @param newRateInPermil The value of the new cashback rate in permil.
     */
    event SetCashbackRate(uint16 oldRateInPermil, uint16 newRateInPermil);

    /**
     * @dev Emitted when a cashback send request succeeded.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The actual amount of the sent cashback.
     * @param nonce The nonce of the cashback.
     */
    event SendCashbackSuccess(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /**
     * @dev Emitted when a cashback send request failed.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The requested amount of cashback to send.
     * @param nonce The nonce of the cashback.
     */
    event SendCashbackFailure(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /**
     * @dev Emitted when a cashback revocation request succeeded.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The actual amount of the revoked cashback.
     * @param nonce The nonce of the cashback.
     */
    event RevokeCashbackSuccess(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /**
     * @dev Emitted when a cashback revocation request failed.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The requested amount of cashback to revoke.
     * @param nonce The nonce of the cashback.
     */
    event RevokeCashbackFailure(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /**
     * @dev Emitted when a cashback increase request succeeded.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The actual amount of the cashback increase.
     * @param nonce The nonce of the cashback.
     */
    event IncreaseCashbackSuccess(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /**
     * @dev Emitted when a cashback increase request failed.
     * @param cashbackDistributor The address of the cashback distributor.
     * @param amount The requested amount of cashback to increase.
     * @param nonce The nonce of the cashback.
     */
    event IncreaseCashbackFailure(address indexed cashbackDistributor, uint256 amount, uint256 nonce);

    /// @dev Emitted when cashback operations are enabled.
    event EnableCashback();

    /// @dev Emitted when cashback operations are disabled.
    event DisableCashback();

    /**
     * @dev Returns the address of the cashback distributor contract.
     */
    function cashbackDistributor() external view returns (address);

    /**
     * @dev Checks if the cashback operations are enabled.
     */
    function cashbackEnabled() external view returns (bool);

    /**
     * @dev Returns the current cashback rate in permil.
     */
    function cashbackRate() external view returns (uint256);

    /**
     * @dev Returns the cashback details for the transaction authorization ID.
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     */
    function getCashback(bytes16 authorizationId) external view returns (Cashback memory);

    /**
     * @dev Sets a new address of the cashback distributor contract.
     *
     * Emits a {SetCashbackDistributor} event.
     *
     * @param newCashbackDistributor The address of the new cashback distributor contract.
     */
    function setCashbackDistributor(address newCashbackDistributor) external;

    /**
     * @dev Sets a new cashback rate.
     *
     * Emits a {SetCashbackRate} event.
     *
     * @param newCashbackRateInPermil The value of the new cashback rate in permil.
     */
    function setCashbackRate(uint16 newCashbackRateInPermil) external;

    /**
     * @dev Enables the cashback operations.
     *
     * Emits a {EnableCashback} event.
     */
    function enableCashback() external;

    /**
     * @dev Disables the cashback operations.
     *
     * Emits a {DisableCashback} event.
     */
    function disableCashback() external;
}

/**
 * @title CardPaymentProcessor types interface
 */
interface ICardPaymentProcessorTypes {
    /**
     * @dev Possible statuses of a payment as an enum.
     *
     * The possible values:
     * - Nonexistent - The payment does not exist (the default value).
     * - Uncleared --- The status immediately after the payment making.
     * - Cleared ----- The payment has been cleared and is ready to be confirmed.
     * - Revoked ----- The payment was revoked due to some technical reason.
     *                 The related tokens have been transferred back to the customer.
     *                 The payment can be made again with the same authorizationId
     *                 if its revocation counter does not reach the configure limit.
     * - Reversed ---- The payment was reversed due to the decision of the off-chain card processing service.
     *                 The related tokens have been transferred back to the customer.
     *                 The payment cannot be made again with the same authorizationId.
     * - Confirmed --- The payment was confirmed.
     *                 The related tokens have been transferred to a special cash-out address.
     *                 The payment cannot be made again with the same authorizationId.
     */
    enum PaymentStatus {
        Nonexistent, // 0
        Uncleared,   // 1
        Cleared,     // 2
        Revoked,     // 3
        Reversed,    // 4
        Confirmed    // 5
    }

    /// @dev Structure with data of a single payment.
    struct Payment {
        address account;            // Account who made the payment.
        uint256 amount;             // Amount of tokens in the payment.
        PaymentStatus status;       // Current status of the payment.
        uint8 revocationCounter;    // Number of payment revocations.
        uint256 compensationAmount; // The total amount of compensation to the account related to the payment
        uint256 refundAmount;       // The total amount of all refunds related to the payment
        uint16 cashbackRate;        // The rate of cashback of the payment
    }
}

/**
 * @title CardPaymentProcessor interface
 * @dev The interface of the wrapper contract for the card payment operations.
 */
interface ICardPaymentProcessor is ICardPaymentProcessorTypes {
    /// @dev Emitted when a payment is made.
    event MakePayment(
        bytes16 indexed authorizationId,
        bytes16 indexed correlationId,
        address indexed account,
        uint256 amount,
        uint8 revocationCounter,
        address sender
    );

    /// @dev Emitted when the amount of a payment is updated.
    event UpdatePaymentAmount(
        bytes16 indexed authorizationId,
        bytes16 indexed correlationId,
        address indexed account,
        uint256 oldAmount,
        uint256 newAmount
    );

    /// @dev Emitted when a payment is cleared.
    event ClearPayment(
        bytes16 indexed authorizationId,
        address indexed account,
        uint256 amount,
        uint256 clearedBalance,
        uint256 unclearedBalance,
        uint8 revocationCounter
    );

    /// @dev Emitted when a payment is uncleared.
    event UnclearPayment(
        bytes16 indexed authorizationId,
        address indexed account,
        uint256 amount,
        uint256 clearedBalance,
        uint256 unclearedBalance,
        uint8 revocationCounter
    );

    /// @dev Emitted when a payment is revoked.
    event RevokePayment(
        bytes16 indexed authorizationId,
        bytes16 indexed correlationId,
        address indexed account,
        uint256 amount,
        uint256 clearedBalance,
        uint256 unclearedBalance,
        bool wasPaymentCleared,
        bytes32 parentTransactionHash,
        uint8 revocationCounter
    );

    /// @dev Emitted when a payment is reversed.
    event ReversePayment(
        bytes16 indexed authorizationId,
        bytes16 indexed correlationId,
        address indexed account,
        uint256 amount,
        uint256 clearedBalance,
        uint256 unclearedBalance,
        bool wasPaymentCleared,
        bytes32 parentTransactionHash,
        uint8 revocationCounter
    );

    /// @dev Emitted when a payment is confirmed.
    event ConfirmPayment(
        bytes16 indexed authorizationId,
        address indexed account,
        uint256 amount,
        uint256 clearedBalance,
        uint8 revocationCounter
    );

    /// @dev Emitted when a payment is refunded.
    event RefundPayment(
        bytes16 indexed authorizationId,
        bytes16 indexed correlationId,
        address indexed account,
        uint256 refundAmount,
        uint256 sentAmount,
        PaymentStatus status
    );

    /// @dev Emitted when the cash-out account is changed.
    event SetCashOutAccount(
        address oldCashOutAccount,
        address newCashOutAccount
    );

    /**
     * @dev Returns the address of the cash-out account.
     */
    function cashOutAccount() external view returns (address);

    /**
     * @dev Returns the address of the underlying token.
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Returns the total balance of uncleared tokens locked in the contract.
     */
    function totalUnclearedBalance() external view returns (uint256);

    /**
     * @dev Returns the total balance of cleared tokens locked in the contract.
     */
    function totalClearedBalance() external view returns (uint256);

    /**
     * @dev Returns the balance of uncleared tokens for an account.
     * @param account The address of the account.
     */
    function unclearedBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the balance of cleared tokens for an account.
     * @param account The address of the account.
     */
    function clearedBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns payment data for a card transaction authorization ID.
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     */
    function paymentFor(bytes16 authorizationId) external view returns (Payment memory);

    /**
     * @dev Checks if the payment associated with the hash of a parent transaction has been revoked.
     * @param parentTxHash The hash of the parent transaction where the payment was made.
     */
    function isPaymentRevoked(bytes32 parentTxHash) external view returns (bool);

    /**
     * @dev Checks if the payment associated with the hash of a parent transaction has been reversed.
     * @param parentTxHash The hash of the parent transaction where the payment was made.
     */
    function isPaymentReversed(bytes32 parentTxHash) external view returns (bool);

    /**
     * @dev Returns the configured limit of revocations for a single payment.
     */
    function revocationLimit() external view returns (uint8);

    /**
     * @dev Makes a card payment.
     *
     * Transfers the underlying tokens from the payer (who is the caller of the function) to this contract.
     * This function is expected to be called by any account.
     *
     * Emits a {MakePayment} event.
     *
     * @param amount The amount of tokens to be transferred to this contract because of the payment.
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     */
    function makePayment(
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external;

    /**
     * @dev Makes a card payment from some other account.
     *
     * Transfers the underlying tokens from the account to this contract.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {MakePayment} event.
     *
     * @param account The account on that behalf the payment is made.
     * @param amount The amount of tokens to be transferred to this contract because of the payment.
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     */
    function makePaymentFrom(
        address account,
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external;

    /**
     * @dev Updates the amount of a previously made payment.
     *
     * Transfers the underlying tokens from the account to this contract or vise versa.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {UpdatePaymentAmount} event.
     *
     * @param newAmount The new amount of the payment.
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     */
    function updatePaymentAmount(
        uint256 newAmount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external;

    /**
     * @dev Executes a clearing operation for a single previously made card payment.
     *
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {ClearPayment} event for the payment.
     *
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     */
    function clearPayment(bytes16 authorizationId) external;

    /**
     * @dev Executes a clearing operation for several previously made card payments.
     *
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {ClearPayment} event for each payment.
     *
     * @param authorizationIds The card transaction authorization IDs from the off-chain card processing backend.
     */
    function clearPayments(bytes16[] memory authorizationIds) external;

    /**
     * @dev Cancels a previously executed clearing operation for a single card payment.
     *
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {UnclearPayment} event for the payment.
     *
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     */
    function unclearPayment(bytes16 authorizationId) external;

    /**
     * @dev Cancels a previously executed clearing operation for several card payments.
     *
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {UnclearPayment} event for the payment.
     *
     * @param authorizationIds The card transaction authorization IDs from the off-chain card processing backend.
     */
    function unclearPayments(bytes16[] memory authorizationIds) external;

    /**
     * @dev Performs the reverse of a previously made card payment.
     *
     * Finalizes the payment: no other operations can be done for the payment after this one.
     * Transfers tokens back from this contract to the payer.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {ReversePayment} event for the payment.
     *
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     * @param parentTxHash The hash of the transaction where the payment was made.
     */
    function reversePayment(
        bytes16 authorizationId,
        bytes16 correlationId,
        bytes32 parentTxHash
    ) external;

    /**
     * @dev Performs the revocation of a previously made card payment and increase its revocation counter.
     *
     * Does not finalize the payment: it can be made again until revocation counter reaches the configured limit.
     * Transfers tokens back from this contract to the payer.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {RevokePayment} event for the payment.
     *
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     * @param parentTxHash The hash of the transaction where the payment was made.
     */
    function revokePayment(
        bytes16 authorizationId,
        bytes16 correlationId,
        bytes32 parentTxHash
    ) external;

    /**
     * @dev Executes the final step of a single card payment processing with token transferring.
     *
     * Finalizes the payment: no other operations can be done for the payment after this one.
     * Transfers previously cleared tokens gotten from a payer to a dedicated cash-out account for further operations.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {ConfirmPayment} event for the payment.
     *
     * @param authorizationId The card transaction authorization ID from the off-chain card processing backend.
     */
    function confirmPayment(bytes16 authorizationId) external;

    /**
     * @dev Executes the final step of several card payments processing with token transferring.
     *
     * Finalizes the payment: no other operations can be done for the payment after this one.
     * Transfers previously cleared tokens gotten from payers to a dedicated cash-out account for further operations.
     * This function can be called by a limited number of accounts that are allowed to execute processing operations.
     *
     * Emits a {ConfirmPayment} event for each payment.
     *
     * @param authorizationIds The card transaction authorization IDs from the off-chain card processing backend.
     */
    function confirmPayments(bytes16[] memory authorizationIds) external;

    /**
     * @dev Makes a refund for a previously made card payment.
     *
     * Emits a {RefundPayment} event.
     *
     * @param amount The amount of tokens to refund.
     * @param authorizationId The card transaction authorization ID.
     * @param correlationId The ID that is correlated to this function call in the off-chain card processing backend.
     */
    function refundPayment(
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external;
}

/**
 * @title CardPaymentProcessor storage version 1
 */
abstract contract CardPaymentProcessorStorageV1 is ICardPaymentProcessorTypes {
    /// @dev The address of the underlying token.
    address internal _token;

    /// @dev The total balance of cleared tokens locked in the contract.
    uint256 internal _totalClearedBalance;

    /// @dev The total balance of uncleared tokens locked in the contract.
    uint256 internal _totalUnclearedBalance;

    /// @dev Mapping of a payment for a given authorization ID.
    mapping(bytes16 => Payment) internal _payments;

    /// @dev Mapping of uncleared balance for a given address.
    mapping(address => uint256) internal _unclearedBalances;

    /// @dev Mapping of cleared balance for a given address.
    mapping(address => uint256) internal _clearedBalances;

    /// @dev Mapping of a payment revocation flag for a given parent transaction hash.
    mapping(bytes32 => bool) internal _paymentRevocationFlags;

    /// @dev Mapping of a payment reversion flag for a given parent transaction hash.
    mapping(bytes32 => bool) internal _paymentReversionFlags;

    /// @dev The revocation limit for a single payment.
    uint8 internal _revocationLimit;
}

/**
 * @title CardPaymentProcessor storage version 2
 */
abstract contract CardPaymentProcessorStorageV2 {
    /// @dev The account to transfer cleared tokens to.
    address internal _cashOutAccount;
}

/**
 * @title CardPaymentProcessor storage version 3
 */
abstract contract CardPaymentProcessorStorageV3 is ICardPaymentCashbackTypes {
    /// @dev The enable flag of the cashback operations.
    bool internal _cashbackEnabled;

    /// @dev The address of the cashback distributor contract.
    address internal _cashbackDistributor;

    /// @dev The current cashback rate in permil (parts per thousand).
    uint16 internal _cashbackRateInPermil;

    /// @dev Mapping of a structure with cashback data for a given authorization ID.
    mapping(bytes16 => Cashback) internal _cashbacks;
}

/**
 * @title CardPaymentProcessor storage
 * @dev Contains storage variables of the {CardPaymentProcessor} contract.
 *
 * We are following Compound's approach of upgrading new contract implementations.
 * See https://github.com/compound-finance/compound-protocol.
 * When we need to add new storage variables, we create a new version of CardPaymentProcessorStorage
 * e.g. CardPaymentProcessorStorage<versionNumber>, so finally it would look like
 * "contract CardPaymentProcessorStorage is CardPaymentProcessorStorageV1, CardPaymentProcessorStorageV2".
 */
abstract contract CardPaymentProcessorStorage is
    CardPaymentProcessorStorageV1,
    CardPaymentProcessorStorageV2,
    CardPaymentProcessorStorageV3 {

}

/**
 * @title CashbackDistributor types interface
 */
interface ICashbackDistributorTypes {
    /**
     * @dev Kinds of a cashback operation as an enum.
     *
     * The possible values:
     * - Manual ------ The cashback is sent manually (the default value).
     * - CardPayment - The cashback is sent through the CardPaymentProcessor contract.
     */
    enum CashbackKind {
        Manual,     // 0
        CardPayment // 1
    }

    /**
     * @dev Statuses of a cashback operation as an enum.
     *
     * The possible values:
     * - Nonexistent - The cashback operation does not exist (the default value).
     * - Success ----- The operation has been successfully executed (cashback sent fully).
     * - Blacklisted - The cashback operation has been refused because the target account is blacklisted.
     * - OutOfFunds -- The cashback operation has been refused because the contract has not enough tokens.
     * - Disabled ---- The cashback operation has been refused because cashback operations are disabled.
     * - Revoked ----- Obsolete and not in use anymore.
     * - Capped ------ The cashback operation has been refused because the cap for the period has been reached.
     * - Partial ----- The operation has been successfully executed (cashback sent partially).
     */
    enum CashbackStatus {
        Nonexistent, // 0
        Success,     // 1
        Blacklisted, // 2
        OutOfFunds,  // 3
        Disabled,    // 4
        Revoked,     // 5
        Capped,      // 6
        Partial      // 7
    }

    /**
     * @dev Statuses of a cashback revocation operation as an enum.
     *
     * The possible values:
     * - Unknown -------- The operation has not been initiated (the default value).
     * - Success -------- The operation has been successfully executed.
     * - Inapplicable --- The operation has been failed because the cashback has not relevant status.
     * - OutOfFunds ----- The operation has been failed because the caller has not enough tokens.
     * - OutOfAllowance - The operation has been failed because the caller has not enough allowance for the contract.
     * - OutOfBalance --- The operation has been failed because the revocation amount exceeds the cashback amount.
     */
    enum RevocationStatus {
        Unknown,        // 0
        Success,        // 1
        Inapplicable,   // 2
        OutOfFunds,     // 3
        OutOfAllowance, // 4
        OutOfBalance    // 5
    }

    /**
     * @dev Statuses of a cashback increase operation as an enum.
     *
     * The possible values:
     * - Nonexistent -- The operation does not exist (the default value).
     * - Success ------ The operation has been successfully executed (cashback sent fully).
     * - Blacklisted -- The operation has been refused because the target account is blacklisted.
     * - OutOfFunds --- The operation has been refused because the contract has not enough tokens.
     * - Disabled ----- The operation has been refused because cashback operations are disabled.
     * - Inapplicable - The operation has been failed because the cashback has not relevant status.
     * - Capped ------- The operation has been refused because the cap for the period has been reached.
     * - Partial ------ The operation has been successfully executed (cashback sent partially).
     */
    enum IncreaseStatus {
        Nonexistent,  // 0
        Success,      // 1
        Blacklisted,  // 2
        OutOfFunds,   // 3
        Disabled,     // 4
        Inapplicable, // 5
        Capped,       // 6
        Partial       // 7
    }

    /// @dev Structure with data of a single cashback operation.
    struct Cashback {
        address token;
        CashbackKind kind;
        CashbackStatus status;
        bytes32 externalId;
        address recipient;
        uint256 amount;
        address sender;
        uint256 revokedAmount;
    }
}

/**
 * @title CashbackDistributor interface
 * @dev The interface of the wrapper contract for the cashback operations.
 */
interface ICashbackDistributor is ICashbackDistributorTypes {
    /**
     * @dev Emitted when a cashback operation is executed.
     *
     * NOTE: The `amount` field of the event contains the actual amount of sent cashback only if
     * the operation was successful or partially successful according to the `status` field,
     * otherwise the `amount` field contains the requested amount of cashback to send.
     *
     * @param token The token contract of the cashback operation.
     * @param kind The kind of the cashback operation.
     * @param status The result of the cashback operation.
     * @param externalId The external identifier of the cashback operation.
     * @param recipient The account to which the cashback is intended.
     * @param amount The requested or actually sent amount of cashback (see the note above).
     * @param sender The account that initiated the cashback operation.
     * @param nonce The nonce of the cashback operation internally assigned by the contract.
     */
    event SendCashback(
        address token,
        CashbackKind kind,
        CashbackStatus indexed status,
        bytes32 indexed externalId,
        address indexed recipient,
        uint256 amount,
        address sender,
        uint256 nonce
    );

    /**
     * @dev Emitted when a cashback operation is revoked.
     * @param token The token contract of the cashback operation.
     * @param cashbackKind The kind of the initial cashback operation.
     * @param cashbackStatus The status of the initial cashback operation before the revocation operation.
     * @param status The status of the revocation.
     * @param externalId The external identifier of the initial cashback operation.
     * @param recipient The account that received the cashback.
     * @param amount The requested amount of cashback to revoke.
     * @param sender The account that initiated the cashback revocation operation.
     * @param nonce The nonce of the initial cashback operation.
     */
    event RevokeCashback(
        address token,
        CashbackKind cashbackKind,
        CashbackStatus cashbackStatus,
        RevocationStatus indexed status,
        bytes32 indexed externalId,
        address indexed recipient,
        uint256 amount,
        address sender,
        uint256 nonce
    );

    /**
     * @dev Emitted when a cashback increase operation is executed.
     *
     * NOTE: The `amount` field of the event contains the actual amount of additionally sent cashback only if
     * the operation was successful or partially successful according to the `status` field,
     * otherwise the `amount` field contains the requested amount of cashback to increase.
     *
     * @param token The token contract of the cashback operation.
     * @param cashbackKind The kind of the initial cashback operation.
     * @param cashbackStatus The status of the initial cashback operation before the increase operation.
     * @param status The status of the increase operation.
     * @param externalId The external identifier of the initial cashback operation.
     * @param recipient The account that received the cashback.
     * @param amount The requested or actual amount of cashback increase (see the note above).
     * @param sender The account that initiated the cashback increase operation.
     * @param nonce The nonce of the initial cashback operation.
     */
    event IncreaseCashback(
        address token,
        CashbackKind cashbackKind,
        CashbackStatus cashbackStatus,
        IncreaseStatus indexed status,
        bytes32 indexed externalId,
        address indexed recipient,
        uint256 amount,
        address sender,
        uint256 nonce
    );

    /**
     * @dev Emitted when cashback operations are enabled.
     * @param sender The account that enabled the operations.
     */
    event Enable(address sender);

    /**
     * @dev Emitted when cashback operations are disabled.
     * @param sender The account that disabled the operations.
     */
    event Disable(address sender);

    /**
     * @dev Sends a cashback to a recipient.
     *
     * Transfers the underlying tokens from the contract to the recipient if there are appropriate conditions.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cashback operations.
     *
     * Emits a {SendCashback} event.
     *
     * @param token The address of the cashback token.
     * @param kind The kind of the cashback operation.
     * @param externalId The external identifier of the cashback operation.
     * @param recipient The account to which the cashback is intended.
     * @param amount The requested amount of cashback to send.
     * @return success True if the cashback has been fully or partially sent.
     * @return sentAmount The amount of the actual cashback sent.
     * @return nonce The nonce of the newly created cashback operation.
     */
    function sendCashback(
        address token,
        CashbackKind kind,
        bytes32 externalId,
        address recipient,
        uint256 amount
    ) external returns (bool success, uint256 sentAmount, uint256 nonce);

    /**
     * @dev Revokes a previously sent cashback.
     *
     * Transfers the underlying tokens from the caller to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cashback operations.
     *
     * Emits a {RevokeCashback} event if the cashback is successfully revoked.
     *
     * @param nonce The nonce of the cashback operation.
     * @param amount The requested amount of cashback to revoke.
     * @return success True if the cashback revocation was successful.
     */
    function revokeCashback(uint256 nonce, uint256 amount) external returns (bool success);

    /**
     * @dev Increases a previously sent cashback.
     *
     * Transfers the underlying tokens from the contract to the recipient if there are appropriate conditions.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cashback operations.
     *
     * Emits a {IncreaseCashback} event if the cashback is successfully increased.
     *
     * @param nonce The nonce of the cashback operation.
     * @param amount The requested amount of cashback increase.
     * @return success True if the additional cashback has been fully or partially sent.
     * @return sentAmount The amount of the actual cashback increase.
     */
    function increaseCashback(uint256 nonce, uint256 amount) external returns (bool success, uint256 sentAmount);

    /**
     * @dev Enables the cashback operations.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to control cashback operations.
     *
     * Emits a {EnableCashback} event.
     */
    function enable() external;

    /**
     * @dev Disables the cashback operations.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to control cashback operations.
     *
     * Emits a {DisableCashback} event.
     */
    function disable() external;

    /**
     * @dev Checks if the cashback operations are enabled.
     */
    function enabled() external view returns (bool);

    /**
     * @dev Returns the nonce of the next cashback operation.
     */
    function nextNonce() external view returns (uint256);

    /**
     * @dev Returns the data of a cashback operation by its nonce.
     * @param nonce The nonce of the cashback operation to return.
     */
    function getCashback(uint256 nonce) external view returns (Cashback memory cashback);

    /**
     * @dev Returns the data of cashback operations by their nonces.
     * @param nonces The array of nonces of cashback operations to return.
     */
    function getCashbacks(uint256[] calldata nonces) external view returns (Cashback[] memory cashbacks);

    /**
     * @dev Returns an array of cashback nonces associated with an external identifier.
     * @param externalId The external cashback identifier to return nonces.
     * @param index The index of the first nonce in the range to return.
     * @param limit The max number of nonces in the range to return.
     */
    function getCashbackNonces(
        bytes32 externalId,
        uint256 index,
        uint256 limit
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns the total amount of all the success cashback operations associated with a token and an external ID.
     * @param token The token contract address of the cashback operations to define the returned total amount.
     * @param externalId The external identifier of the cashback operations to define the returned total amount.
     */
    function getTotalCashbackByTokenAndExternalId(address token, bytes32 externalId) external view returns (uint256);

    /**
     * @dev Returns the total amount of all the success cashback operations associated with a token and a recipient.
     * @param token The token contract address of the cashback operations to define the returned total amount.
     * @param recipient The recipient address of the cashback operations to define the returned total amount.
     */
    function getTotalCashbackByTokenAndRecipient(address token, address recipient) external view returns (uint256);
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * @title Pausable contract interface
 * @author CloudWalk Inc.
 * @dev Allows to trigger the paused or unpaused state of the contract.
 */
interface IPausable {
    // -------------------- Functions -----------------------------------

    /**
     * @dev Triggers the paused state of the contract.
     */
    function pause() external;

    /**
     * @dev Triggers the unpaused state of the contract.
     */
    function unpause() external;
}

/**
 * @title PausableExtUpgradeable base contract
 * @author CloudWalk Inc.
 * @dev Extends the OpenZeppelin's {PausableUpgradeable} contract by adding the {PAUSER_ROLE} role.
 *
 * This contract is used through inheritance. It introduces the {PAUSER_ROLE} role that is allowed to
 * trigger the paused or unpaused state of the contract that is inherited from this one.
 */
abstract contract PausableExtUpgradeable is AccessControlUpgradeable, PausableUpgradeable, IPausable {
    /// @dev The role of pauser that is allowed to trigger the paused or unpaused state of the contract.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // -------------------- Functions --------------------------------

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function __PausableExt_init(bytes32 pauserRoleAdmin) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        __PausableExt_init_unchained(pauserRoleAdmin);
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {PausableExtUpgradeable-__PausableExt_init}.
     */
    function __PausableExt_init_unchained(bytes32 pauserRoleAdmin) internal onlyInitializing {
        _setRoleAdmin(PAUSER_ROLE, pauserRoleAdmin);
    }

    /**
     * @dev Triggers the paused state of the contract.
     *
     * Requirements:
     *
     * - The caller must have the {PAUSER_ROLE} role.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Triggers the unpaused state of the contract.
     *
     * Requirements:
     *
     * - The caller must have the {PAUSER_ROLE} role.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}

/**
 * @title Blacklistable contract interface
 * @author CloudWalk Inc.
 * @dev Allows to blacklist and unblacklist accounts.
 */
interface IBlacklistable {
    // -------------------- Events -----------------------------------

    /// @dev Emitted when an account is blacklisted.
    event Blacklisted(address indexed account);

    /// @dev Emitted when an account is unblacklisted.
    event UnBlacklisted(address indexed account);

    /// @dev Emitted when an account is self blacklisted.
    event SelfBlacklisted(address indexed account);

    // -------------------- Functions -----------------------------------

    /**
     * @dev Adds an account to the blacklist.
     *
     * Emits a {Blacklisted} event.
     *
     * @param account The address to add to the blacklist.
     */
    function blacklist(address account) external;

    /**
     * @dev Removes an account from the blacklist.
     *
     * Emits an {UnBlacklisted} event.
     *
     * @param account The address to remove from the blacklist.
     */
    function unBlacklist(address account) external;

    /**
     * @dev Adds the message sender to the blacklist.
     *
     * Emits a {SelfBlacklisted} event.
     */
    function selfBlacklist() external;

    /**
     * @dev Checks if an account is blacklisted.
     * @param account The address to check for presence in the blacklist.
     * @return True if the account is present in the blacklist.
     */
    function isBlacklisted(address account) external returns (bool);
}

/**
 * @title BlacklistableUpgradeable base contract
 * @author CloudWalk Inc.
 * @dev Allows to blacklist and unblacklist accounts using the {BLACKLISTER_ROLE} role.
 *
 * This contract is used through inheritance. It makes available the modifier `notBlacklisted`,
 * which can be applied to functions to restrict their usage to not blacklisted accounts only.
 */
abstract contract BlacklistableUpgradeable is AccessControlUpgradeable, IBlacklistable {
    /// @dev The role of the blacklister that is allowed to blacklist and unblacklist accounts.
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    /// @dev Mapping of presence in the blacklist for a given address.
    mapping(address => bool) private _blacklisted;

    // -------------------- Errors -----------------------------------

    /// @dev The account is blacklisted.
    error BlacklistedAccount(address account);

    // -------------------- Modifiers --------------------------------

    /**
     * @dev Throws if called by a blacklisted account.
     * @param account The address to check for presence in the blacklist.
     */
    modifier notBlacklisted(address account) {
        if (_blacklisted[account]) {
            revert BlacklistedAccount(account);
        }
        _;
    }

    // -------------------- Functions --------------------------------

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function __Blacklistable_init(bytes32 blacklisterRoleAdmin) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();

        __Blacklistable_init_unchained(blacklisterRoleAdmin);
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {BlacklistableUpgradeable-__Blacklistable_init}.
     */
    function __Blacklistable_init_unchained(bytes32 blacklisterRoleAdmin) internal onlyInitializing {
        _setRoleAdmin(BLACKLISTER_ROLE, blacklisterRoleAdmin);
    }

    /**
     * @dev Adds an account to the blacklist.
     *
     * Requirements:
     *
     * - The caller must have the {BLACKLISTER_ROLE} role.
     *
     * Emits a {Blacklisted} event.
     *
     * @param account The address to blacklist.
     */
    function blacklist(address account) public onlyRole(BLACKLISTER_ROLE) {
        if (_blacklisted[account]) {
            return;
        }

        _blacklisted[account] = true;

        emit Blacklisted(account);
    }

    /**
     * @dev Removes an account from the blacklist.
     *
     * Requirements:
     *
     * - The caller must have the {BLACKLISTER_ROLE} role.
     *
     * Emits an {UnBlacklisted} event.
     *
     * @param account The address to remove from the blacklist.
     */
    function unBlacklist(address account) public onlyRole(BLACKLISTER_ROLE) {
        if (!_blacklisted[account]) {
            return;
        }

        _blacklisted[account] = false;

        emit UnBlacklisted(account);
    }

    /**
     * @dev Adds the message sender to the blacklist.
     *
     * Emits a {SelfBlacklisted} event.
     * Emits a {Blacklisted} event.
     */
    function selfBlacklist() public {
        address sender = _msgSender();

        if (_blacklisted[sender]) {
            return;
        }

        _blacklisted[sender] = true;

        emit SelfBlacklisted(sender);
        emit Blacklisted(sender);
    }

    /**
     * @dev Checks if an account is blacklisted.
     * @param account The address to check for presence in the blacklist.
     * @return True if the account is present in the blacklist.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[49] private __gap;
}

/**
 * @title Rescuable contract interface
 * @author CloudWalk Inc.
 * @dev Allows to rescue ERC20 tokens locked up in the contract.
 */
interface IRescuable {
    // -------------------- Functions -----------------------------------

    /**
     * @dev Withdraws ERC20 tokens locked up in the contract.
     * @param token The address of the ERC20 token contract.
     * @param to The address of the recipient of tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function rescueERC20(address token, address to, uint256 amount) external;
}

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title RescuableUpgradeable base contract
 * @author CloudWalk Inc.
 * @dev Allows to rescue ERC20 tokens locked up in the contract using the {RESCUER_ROLE} role.
 *
 * This contract is used through inheritance. It introduces the {RESCUER_ROLE} role that is allowed to
 * rescue tokens locked up in the contract that is inherited from this one.
 */
abstract contract RescuableUpgradeable is AccessControlUpgradeable, IRescuable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The role of rescuer that is allowed to rescue tokens locked up in the contract.
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");

    // -------------------- Functions --------------------------------

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function __Rescuable_init(bytes32 rescuerRoleAdmin) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();

        __Rescuable_init_unchained(rescuerRoleAdmin);
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {RescuableUpgradeable-__Rescuable_init}.
     */
    function __Rescuable_init_unchained(bytes32 rescuerRoleAdmin) internal onlyInitializing {
        _setRoleAdmin(RESCUER_ROLE, rescuerRoleAdmin);
    }

    /**
     * @dev Withdraws ERC20 tokens locked up in the contract.
     *
     * Requirements:
     *
     * - The caller must have the {RESCUER_ROLE} role.
     *
     * @param token The address of the ERC20 token contract.
     * @param to The address of the recipient of tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(RESCUER_ROLE) {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}

/**
 * @title StoragePlaceholder200 base contract
 * @author CloudWalk Inc.
 * @dev Reserves 200 storage slots.
 * Such a storage placeholder contract allows future replacement of it with other contracts
 * without shifting down storage in the inheritance chain.
 *
 * E.g. the following code:
 * ```
 * abstract contract StoragePlaceholder200 {
 *     uint256[200] private __gap;
 * }
 *
 * contract A is B, StoragePlaceholder200, C {
 *     //Some implementation
 * }
 * ```
 * can be replaced with the following code without a storage shifting issue:
 * ```
 * abstract contract StoragePlaceholder150 {
 *     uint256[150] private __gap;
 * }
 *
 * abstract contract X {
 *     uint256[50] public values;
 *     // No more storage variables. Some set of functions should be here.
 * }
 *
 * contract A is B, X, StoragePlaceholder150, C {
 *     //Some implementation
 * }
 * ```
 */
abstract contract StoragePlaceholder200 {
    uint256[200] private __gap;
}

/**
 * @title CardPaymentProcessor contract
 * @dev Wrapper contract for the card payment operations.
 */
contract CardPaymentProcessor is
    AccessControlUpgradeable,
    BlacklistableUpgradeable,
    PausableExtUpgradeable,
    RescuableUpgradeable,
    StoragePlaceholder200,
    CardPaymentProcessorStorage,
    ICardPaymentProcessor,
    ICardPaymentCashback
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The role of this contract owner.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev The role of executor that is allowed to execute the card payment operations.
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @dev The maximum allowable cashback rate in permil (1 permil = 0.1 %).
    uint16 public constant MAX_CASHBACK_RATE_IN_PERMIL = 250;

    // -------------------- Events -----------------------------------

    /**
     * @dev Emitted when the revocation limit is changed.
     * @param oldLimit The old value of the revocation limit.
     * @param newLimit The new value of the revocation limit.
     */
    event SetRevocationLimit(uint8 oldLimit, uint8 newLimit);

    // -------------------- Errors -----------------------------------

    /// @dev The zero token address has been passed as a function argument.
    error ZeroTokenAddress();

    /// @dev The zero account address has been passed as a function argument.
    error ZeroAccount();

    /// @dev Zero authorization ID has been passed as a function argument.
    error ZeroAuthorizationId();

    /// @dev The payment with the provided authorization ID already exists and is not revoked.
    error PaymentAlreadyExists();

    /// @dev Payment with the provided authorization ID is uncleared, but it must be cleared.
    error PaymentAlreadyUncleared();

    /// @dev Payment with the provided authorization ID is cleared, but it must be uncleared.
    error PaymentAlreadyCleared();

    /// @dev The payment with the provided authorization ID does not exist.
    error PaymentNotExist();

    /// @dev Empty array of authorization IDs has been passed as a function argument.
    error EmptyAuthorizationIdsArray();

    /// @dev Zero parent transaction hash has been passed as a function argument.
    error ZeroParentTransactionHash();

    /// @dev The cash-out account is not configured.
    error ZeroCashOutAccount();

    /**
     * @dev The payment with the provided authorization ID has an inappropriate status.
     * @param currentStatus The current status of payment with the provided authorization ID.
     */
    error InappropriatePaymentStatus(PaymentStatus currentStatus);

    /**
     * @dev Revocation counter of the payment reached the configured limit.
     * @param configuredRevocationLimit The configured revocation limit.
     */
    error RevocationLimitReached(uint8 configuredRevocationLimit);

    /// @dev A new cash-out account is the same as the previously set one.
    error CashOutAccountUnchanged();

    /// @dev A new cashback rate is the same as previously set one.
    error CashbackRateUnchanged();

    /// @dev A new cashback rate exceeds the allowed maximum.
    error CashbackRateExcess();

    /// @dev The cashback operations are already enabled.
    error CashbackAlreadyEnabled();

    /// @dev The cashback operations are already disabled.
    error CashbackAlreadyDisabled();

    /// @dev The zero cashback distributor address has been passed as a function argument.
    error CashbackDistributorZeroAddress();

    /// @dev The cashback distributor contract is not configured.
    error CashbackDistributorNotConfigured();

    /// @dev The cashback distributor contract is already configured.
    error CashbackDistributorAlreadyConfigured();

    /// @dev The requested refund amount does not meet the requirements.
    error InappropriateRefundAmount();

    /// @dev The new amount of the payment does not meet the requirements.
    error InappropriateNewPaymentAmount();

    // ------------------- Functions ---------------------------------

    /**
     * @dev The initialize function of the upgradable contract.
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
     *
     * Requirements:
     *
     * - The passed token address must not be zero.
     *
     * @param token_ The address of a token to set as the underlying one.
     */
    function initialize(address token_) external initializer {
        __CardPaymentProcessor_init(token_);
    }

    function __CardPaymentProcessor_init(address token_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Blacklistable_init_unchained(OWNER_ROLE);
        __Pausable_init_unchained();
        __PausableExt_init_unchained(OWNER_ROLE);
        __Rescuable_init_unchained(OWNER_ROLE);

        __CardPaymentProcessor_init_unchained(token_);
    }

    function __CardPaymentProcessor_init_unchained(address token_) internal onlyInitializing {
        if (token_ == address(0)) {
            revert ZeroTokenAddress();
        }

        _token = token_;
        _revocationLimit = type(uint8).max;

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, _msgSender());
    }

    /**
     * @dev See {ICardPaymentProcessor-makePayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must must not be blacklisted.
     * - The authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must not exist or be revoked.
     * - The payment's revocation counter must be equal to zero or less than the configured revocation limit.
     */
    function makePayment(
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external whenNotPaused notBlacklisted(_msgSender()) {
        address sender = _msgSender();
        makePaymentInternal(sender, sender, amount, authorizationId, correlationId);
    }

    /**
     * @dev See {ICardPaymentProcessor-makePaymentFor}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The payment account address must not be zero.
     * - The authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must not exist or be revoked.
     * - The payment's revocation counter must be equal to zero or less than the configured revocation limit.
     */
    function makePaymentFrom(
        address account,
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (account == address(0)) {
            revert ZeroAccount();
        }
        makePaymentInternal(_msgSender(), account, amount, authorizationId, correlationId);
    }

    /**
     * @dev See {ICardPaymentProcessor-updatePaymentAmount}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "uncleared" status.
     * - The new amount must not exceed the existing refund amount.
     */
    function updatePaymentAmount(
        uint256 newAmount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];
        PaymentStatus status = payment.status;
        address account = payment.account;
        uint256 oldPaymentAmount = payment.amount;
        uint256 refundAmount = payment.refundAmount;

        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }
        if (status != PaymentStatus.Uncleared) {
            revert InappropriatePaymentStatus(status);
        }
        if (refundAmount > newAmount) {
            revert InappropriateNewPaymentAmount();
        }

        uint256 newCompensationAmount = refundAmount +
            calculateCashback(newAmount - refundAmount, payment.cashbackRate);
        payment.amount = newAmount;

        if (newAmount >= oldPaymentAmount) {
            uint256 oldCompensationAmount = payment.compensationAmount;
            uint256 cashbackIncreaseAmount = newCompensationAmount - oldCompensationAmount;
            uint256 paymentAmountDiff = newAmount - oldPaymentAmount;

            _totalUnclearedBalance += paymentAmountDiff;
            _unclearedBalances[account] += paymentAmountDiff;
            IERC20Upgradeable(_token).safeTransferFrom(account, address(this), paymentAmountDiff);

            cashbackIncreaseAmount = increaseCashbackInternal(authorizationId, cashbackIncreaseAmount);
            payment.compensationAmount = oldCompensationAmount + cashbackIncreaseAmount;
        } else {
            uint256 cashbackRevocationAmount = payment.compensationAmount - newCompensationAmount;
            uint256 paymentAmountDiff = oldPaymentAmount - newAmount;
            uint256 sentAmount = paymentAmountDiff - cashbackRevocationAmount;

            _totalUnclearedBalance -= paymentAmountDiff;
            _unclearedBalances[account] -= paymentAmountDiff;
            IERC20Upgradeable(_token).safeTransfer(account, sentAmount);

            revokeCashbackInternal(authorizationId, cashbackRevocationAmount);
            payment.compensationAmount = newCompensationAmount;
        }

        emit UpdatePaymentAmount(
            authorizationId,
            correlationId,
            account,
            oldPaymentAmount,
            newAmount
        );
    }

    /**
     * @dev See {ICardPaymentProcessor-clearPayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "uncleared" status.
     */
    function clearPayment(bytes16 authorizationId) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        uint256 amount = clearPaymentInternal(authorizationId);

        _totalUnclearedBalance = _totalUnclearedBalance - amount;
        _totalClearedBalance = _totalClearedBalance + amount;
    }

    /**
     * @dev See {ICardPaymentProcessor-clearPayments}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input array of authorization IDs must not be empty.
     * - All authorization IDs in the input array must not be zero.
     * - All payments linked with the authorization IDs must have the "uncleared" status.
     */
    function clearPayments(bytes16[] memory authorizationIds) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (authorizationIds.length == 0) {
            revert EmptyAuthorizationIdsArray();
        }

        uint256 totalAmount = 0;
        uint256 len = authorizationIds.length;
        for (uint256 i = 0; i < len; i++) {
            totalAmount += clearPaymentInternal(authorizationIds[i]);
        }

        _totalUnclearedBalance = _totalUnclearedBalance - totalAmount;
        _totalClearedBalance = _totalClearedBalance + totalAmount;
    }

    /**
     * @dev See {ICardPaymentProcessor-unclearPayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "cleared" status.
     */
    function unclearPayment(bytes16 authorizationId) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        uint256 amount = unclearPaymentInternal(authorizationId);

        _totalClearedBalance = _totalClearedBalance - amount;
        _totalUnclearedBalance = _totalUnclearedBalance + amount;
    }

    /**
     * @dev See {ICardPaymentProcessor-unclearPayments}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input array of authorization IDs must not be empty.
     * - All authorization IDs in the input array must not be zero.
     * - All payments linked with the authorization IDs must have the "cleared" status.
     */
    function unclearPayments(bytes16[] memory authorizationIds) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (authorizationIds.length == 0) {
            revert EmptyAuthorizationIdsArray();
        }

        uint256 totalAmount = 0;
        uint256 len = authorizationIds.length;
        for (uint256 i = 0; i < len; i++) {
            totalAmount = totalAmount + unclearPaymentInternal(authorizationIds[i]);
        }

        _totalClearedBalance = _totalClearedBalance - totalAmount;
        _totalUnclearedBalance = _totalUnclearedBalance + totalAmount;
    }

    /**
     * @dev See {ICardPaymentProcessor-reversePayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID and parent transaction hash of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "cleared" or "uncleared" status.
     */
    function reversePayment(
        bytes16 authorizationId,
        bytes16 correlationId,
        bytes32 parentTxHash
    ) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        cancelPaymentInternal(
            authorizationId,
            correlationId,
            parentTxHash,
            PaymentStatus.Reversed
        );
    }

    /**
     * @dev See {ICardPaymentProcessor-revokePayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID and parent transaction hash of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "cleared" or "uncleared" status.
     * - The revocation limit of payments should not be zero.
     */
    function revokePayment(
        bytes16 authorizationId,
        bytes16 correlationId,
        bytes32 parentTxHash
    ) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (_revocationLimit == 0) {
            revert RevocationLimitReached(0);
        }

        cancelPaymentInternal(
            authorizationId,
            correlationId,
            parentTxHash,
            PaymentStatus.Revoked
        );
    }

    /**
     * @dev See {ICardPaymentProcessor-confirmPayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID of the payment must not be zero.
     * - The payment linked with the authorization ID must have the "cleared" status.
     */
    function confirmPayment(bytes16 authorizationId)
        public
        whenNotPaused
        onlyRole(EXECUTOR_ROLE)
    {
        uint256 amount = confirmPaymentInternal(authorizationId);
        _totalClearedBalance -= amount;
        IERC20Upgradeable(_token).safeTransfer(requireCashOutAccount(), amount);
    }

    /**
     * @dev See {ICardPaymentProcessor-confirmPayments}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input array of authorization IDs must not be empty.
     * - All authorization IDs in the input array must not be zero.
     * - All payments linked with the authorization IDs must have the "cleared" status.
     */
    function confirmPayments(bytes16[] memory authorizationIds)
        public
        whenNotPaused
        onlyRole(EXECUTOR_ROLE)
    {
        if (authorizationIds.length == 0) {
            revert EmptyAuthorizationIdsArray();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < authorizationIds.length; i++) {
            totalAmount += confirmPaymentInternal(authorizationIds[i]);
        }

        _totalClearedBalance -= totalAmount;
        IERC20Upgradeable(_token).safeTransfer(requireCashOutAccount(), totalAmount);
    }

    /**
     * @dev See {ICardPaymentProcessor-refundPayment}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {EXECUTOR_ROLE} role.
     * - The input authorization ID of the payment must not be zero.
     */
    function refundPayment(
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) external whenNotPaused onlyRole(EXECUTOR_ROLE) {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];
        PaymentStatus status = payment.status;
        address account = payment.account;
        uint256 paymentAmount = payment.amount;
        uint256 newRefundAmount = payment.refundAmount + amount;

        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }
        if (status != PaymentStatus.Uncleared && status != PaymentStatus.Cleared && status != PaymentStatus.Confirmed) {
            revert InappropriatePaymentStatus(status);
        }
        if (newRefundAmount > paymentAmount) {
            revert InappropriateRefundAmount();
        }

        uint256 newCompensationAmount = newRefundAmount +
            calculateCashback(paymentAmount - newRefundAmount, payment.cashbackRate);
        uint256 sentAmount = newCompensationAmount - payment.compensationAmount;
        uint256 revokedCashbackAmount = amount - sentAmount;

        payment.refundAmount = newRefundAmount;
        payment.compensationAmount = newCompensationAmount;

        if (status == PaymentStatus.Uncleared) {
            _totalUnclearedBalance -= amount;
            _unclearedBalances[account] -= amount;
            IERC20Upgradeable(_token).safeTransfer(account, sentAmount);
        } else if (status == PaymentStatus.Cleared) {
            _totalClearedBalance -= amount;
            _clearedBalances[account] -= amount;
            IERC20Upgradeable(_token).safeTransfer(account, sentAmount);
        } else { // status == PaymentStatus.ConfirmPayment
            address cashOutAccount_ = requireCashOutAccount();
            IERC20Upgradeable token = IERC20Upgradeable(_token);
            token.safeTransferFrom(cashOutAccount_, account, sentAmount);
            token.safeTransferFrom(cashOutAccount_, address(this), revokedCashbackAmount);
        }

        revokeCashbackInternal(authorizationId, revokedCashbackAmount);

        emit RefundPayment(
            authorizationId,
            correlationId,
            account,
            amount,
            sentAmount,
            status
        );
    }

    /**
     * @dev Sets a new value for the revocation limit.
     * If the limit equals 0 or 1 a payment with the same authorization ID cannot be repeated after the revocation.
     *
     * Requirements:
     *
     * - The caller must have the {EXECUTOR_ROLE} role.
     *
     * Emits a {SetRevocationLimit} event if the new limit differs from the old value.
     *
     * @param newLimit The new revocation limit value to be set.
     */
    function setRevocationLimit(uint8 newLimit) external onlyRole(OWNER_ROLE) {
        uint8 oldLimit = _revocationLimit;
        if (oldLimit == newLimit) {
            return;
        }

        _revocationLimit = newLimit;
        emit SetRevocationLimit(oldLimit, newLimit);
    }

    /**
     * @dev See {ICardPaymentProcessor-cashOutAccount}.
     */
    function cashOutAccount() external view returns (address) {
        return _cashOutAccount;
    }

    /**
     * @dev See {ICardPaymentProcessor-underlyingToken}.
     */
    function underlyingToken() external view returns (address) {
        return _token;
    }

    /**
     * @dev See {ICardPaymentProcessor-totalUnclearedBalance}.
     */
    function totalUnclearedBalance() external view returns (uint256) {
        return _totalUnclearedBalance;
    }

    /**
     * @dev See {ICardPaymentProcessor-totalClearedBalance}.
     */
    function totalClearedBalance() external view returns (uint256) {
        return _totalClearedBalance;
    }

    /**
     * @dev See {ICardPaymentProcessor-unclearedBalanceOf}.
     */
    function unclearedBalanceOf(address account) external view returns (uint256) {
        return _unclearedBalances[account];
    }

    /**
     * @dev See {ICardPaymentProcessor-clearedBalanceOf}.
     */
    function clearedBalanceOf(address account) external view returns (uint256) {
        return _clearedBalances[account];
    }

    /**
     * @dev See {ICardPaymentProcessor-paymentFor}.
     */
    function paymentFor(bytes16 authorizationId) external view returns (Payment memory) {
        return _payments[authorizationId];
    }

    /**
     * @dev See {ICardPaymentProcessor-isPaymentRevoked}.
     */
    function isPaymentRevoked(bytes32 parentTxHash) external view returns (bool) {
        return _paymentRevocationFlags[parentTxHash];
    }

    /**
     * @dev See {ICardPaymentProcessor-isPaymentReversed}.
     */
    function isPaymentReversed(bytes32 parentTxHash) external view returns (bool) {
        return _paymentReversionFlags[parentTxHash];
    }

    /**
     * @dev See {ICardPaymentProcessor-revocationLimit}.
     */
    function revocationLimit() external view returns (uint8) {
        return _revocationLimit;
    }

    /**
     * @dev See {ICardPaymentCashback-cashbackDistributor}.
     */
    function cashbackDistributor() external view returns (address) {
        return _cashbackDistributor;
    }

    /**
     * @dev See {ICardPaymentCashback-cashbackEnabled}.
     */
    function cashbackEnabled() external view returns (bool) {
        return _cashbackEnabled;
    }

    /**
     * @dev See {ICardPaymentCashback-cashbackRate}.
     */
    function cashbackRate() external view returns (uint256) {
        return _cashbackRateInPermil;
    }

    /**
     * @dev See {ICardPaymentCashback-getCashback}.
     */
    function getCashback(bytes16 authorizationId) external view returns (Cashback memory) {
        return _cashbacks[authorizationId];
    }

    /**
     * @dev See {ICardPaymentCashback-setCashbackDistributor}.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The new cashback distributor address must not be zero.
     * - The new cashback distributor can be set only once.
     */
    function setCashbackDistributor(address newCashbackDistributor) external onlyRole(OWNER_ROLE) {
        address oldCashbackDistributor = _cashbackDistributor;

        if (newCashbackDistributor == address(0)) {
            revert CashbackDistributorZeroAddress();
        }
        if (oldCashbackDistributor != address(0)) {
            revert CashbackDistributorAlreadyConfigured();
        }

        _cashbackDistributor = newCashbackDistributor;

        emit SetCashbackDistributor(oldCashbackDistributor, newCashbackDistributor);

        IERC20Upgradeable(_token).approve(newCashbackDistributor, type(uint256).max);
    }

    /**
     * @dev See {ICardPaymentCashback-setCashbackRate}.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The new rate must differ from the previously set one.
     * - The new rate must not exceed the allowable maximum specified in the {MAX_CASHBACK_RATE_IN_PERMIL} constant.
     */
    function setCashbackRate(uint16 newCashbackRateInPermil) external onlyRole(OWNER_ROLE) {
        uint16 oldCashbackRateInPermil = _cashbackRateInPermil;
        if (newCashbackRateInPermil == oldCashbackRateInPermil) {
            revert CashbackRateUnchanged();
        }
        if (newCashbackRateInPermil > MAX_CASHBACK_RATE_IN_PERMIL) {
            revert CashbackRateExcess();
        }

        _cashbackRateInPermil = newCashbackRateInPermil;

        emit SetCashbackRate(oldCashbackRateInPermil, newCashbackRateInPermil);
    }

    /**
     * @dev See {ICardPaymentCashback-enableCashback}.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The cashback operations must not be already enabled.
     * - The address of the current cashback distributor must not be zero.
     */
    function enableCashback() external onlyRole(OWNER_ROLE) {
        if (_cashbackEnabled) {
            revert CashbackAlreadyEnabled();
        }
        if (_cashbackDistributor == address(0)) {
            revert CashbackDistributorNotConfigured();
        }

        _cashbackEnabled = true;

        emit EnableCashback();
    }

    /**
     * @dev See {ICardPaymentCashback-disableCashback}.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The cashback operations must not be already disabled.
     */
    function disableCashback() external onlyRole(OWNER_ROLE) {
        if (!_cashbackEnabled) {
            revert CashbackAlreadyDisabled();
        }

        _cashbackEnabled = false;

        emit DisableCashback();
    }

    /**
     * @dev See {ICardPaymentCashback-setCashOutAccount}.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The new cash-out account must differ from the previously set one.
     */
    function setCashOutAccount(address newCashOutAccount) external onlyRole(OWNER_ROLE) {
        address oldCashOutAccount = _cashOutAccount;

        if (newCashOutAccount == oldCashOutAccount) {
            revert CashOutAccountUnchanged();
        }

        _cashOutAccount = newCashOutAccount;

        emit SetCashOutAccount(oldCashOutAccount, newCashOutAccount);
    }

    function makePaymentInternal(
        address sender,
        address account,
        uint256 amount,
        bytes16 authorizationId,
        bytes16 correlationId
    ) internal {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];

        PaymentStatus status = payment.status;
        if (
            status != PaymentStatus.Nonexistent &&
            status != PaymentStatus.Revoked
        ) {
            revert PaymentAlreadyExists();
        }

        uint8 revocationCounter = payment.revocationCounter;
        if (revocationCounter != 0 && revocationCounter >= _revocationLimit) {
            revert RevocationLimitReached(_revocationLimit);
        }

        payment.account = account;
        payment.amount = amount;
        payment.status = PaymentStatus.Uncleared;

        _unclearedBalances[account] = _unclearedBalances[account] + amount;
        _totalUnclearedBalance = _totalUnclearedBalance + amount;

        emit MakePayment(
            authorizationId,
            correlationId,
            account,
            amount,
            revocationCounter,
            sender
        );

        IERC20Upgradeable(_token).safeTransferFrom(account, address(this), amount);
        (payment.compensationAmount, payment.cashbackRate) = sendCashbackInternal(account, amount, authorizationId);
    }

    function clearPaymentInternal(bytes16 authorizationId) internal returns (uint256 amount) {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];

        PaymentStatus status = payment.status;
        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }
        if (status == PaymentStatus.Cleared) {
            revert PaymentAlreadyCleared();
        }
        if (status != PaymentStatus.Uncleared) {
            revert InappropriatePaymentStatus(status);
        }
        payment.status = PaymentStatus.Cleared;

        address account = payment.account;
        amount = payment.amount - payment.refundAmount;

        uint256 newUnclearedBalance = _unclearedBalances[account] - amount;
        _unclearedBalances[account] = newUnclearedBalance;
        uint256 newClearedBalance = _clearedBalances[account] + amount;
        _clearedBalances[account] = newClearedBalance;

        emit ClearPayment(
            authorizationId,
            account,
            amount,
            newClearedBalance,
            newUnclearedBalance,
            payment.revocationCounter
        );
    }

    function unclearPaymentInternal(bytes16 authorizationId) internal returns (uint256 amount) {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];

        PaymentStatus status = payment.status;
        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }
        if (status == PaymentStatus.Uncleared) {
            revert PaymentAlreadyUncleared();
        }
        if (status != PaymentStatus.Cleared) {
            revert InappropriatePaymentStatus(status);
        }
        payment.status = PaymentStatus.Uncleared;

        address account = payment.account;
        amount = payment.amount - payment.refundAmount;

        uint256 newClearedBalance = _clearedBalances[account] - amount;
        _clearedBalances[account] = newClearedBalance;
        uint256 newUnclearedBalance = _unclearedBalances[account] + amount;
        _unclearedBalances[account] = newUnclearedBalance;

        emit UnclearPayment(
            authorizationId,
            account,
            amount,
            newClearedBalance,
            newUnclearedBalance,
            payment.revocationCounter
        );
    }

    function confirmPaymentInternal(bytes16 authorizationId) internal returns (uint256 amount) {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }

        Payment storage payment = _payments[authorizationId];

        PaymentStatus status = payment.status;
        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }
        if (status != PaymentStatus.Cleared) {
            revert InappropriatePaymentStatus(status);
        }
        payment.status = PaymentStatus.Confirmed;

        address account = payment.account;
        amount = payment.amount - payment.refundAmount;
        uint256 newClearedBalance = _clearedBalances[account] - amount;
        _clearedBalances[account] = newClearedBalance;

        emit ConfirmPayment(authorizationId, account, amount, newClearedBalance, payment.revocationCounter);
    }

    struct CancelPaymentVars {
        address account;
        uint256 remainingPaymentAmount;
        uint256 revokedCashbackAmount;
        uint256 sentAmount;
    }

    function cancelPaymentInternal(
        bytes16 authorizationId,
        bytes16 correlationId,
        bytes32 parentTxHash,
        PaymentStatus targetStatus
    ) internal {
        if (authorizationId == 0) {
            revert ZeroAuthorizationId();
        }
        if (parentTxHash == 0) {
            revert ZeroParentTransactionHash();
        }

        Payment storage payment = _payments[authorizationId];
        PaymentStatus status = payment.status;

        if (status == PaymentStatus.Nonexistent) {
            revert PaymentNotExist();
        }

        CancelPaymentVars memory cancellation;
        cancellation.account = payment.account;
        cancellation.sentAmount = payment.amount - payment.compensationAmount;
        cancellation.remainingPaymentAmount = payment.amount - payment.refundAmount;
        cancellation.revokedCashbackAmount = cancellation.remainingPaymentAmount - cancellation.sentAmount;

        if (status == PaymentStatus.Uncleared) {
            _totalUnclearedBalance -= cancellation.remainingPaymentAmount;
            _unclearedBalances[cancellation.account] -= cancellation.remainingPaymentAmount;
        } else if (status == PaymentStatus.Cleared) {
            _totalClearedBalance -= cancellation.remainingPaymentAmount;
            _clearedBalances[cancellation.account] -= cancellation.remainingPaymentAmount;
        } else {
            revert InappropriatePaymentStatus(status);
        }

        payment.compensationAmount = 0;
        payment.refundAmount = 0;

        if (targetStatus == PaymentStatus.Revoked) {
            payment.status = PaymentStatus.Revoked;
            _paymentRevocationFlags[parentTxHash] = true;
            uint8 newRevocationCounter = payment.revocationCounter + 1;
            payment.revocationCounter = newRevocationCounter;

            emit RevokePayment(
                authorizationId,
                correlationId,
                cancellation.account,
                cancellation.sentAmount,
                _clearedBalances[cancellation.account],
                _unclearedBalances[cancellation.account],
                status == PaymentStatus.Cleared,
                parentTxHash,
                newRevocationCounter
            );
        } else {
            payment.status = PaymentStatus.Reversed;
            _paymentReversionFlags[parentTxHash] = true;

            emit ReversePayment(
                authorizationId,
                correlationId,
                cancellation.account,
                cancellation.sentAmount,
                _clearedBalances[cancellation.account],
                _unclearedBalances[cancellation.account],
                status == PaymentStatus.Cleared,
                parentTxHash,
                payment.revocationCounter
            );
        }

        IERC20Upgradeable(_token).safeTransfer(cancellation.account, cancellation.sentAmount);
        revokeCashbackInternal(authorizationId, cancellation.revokedCashbackAmount);
    }

    function sendCashbackInternal(
        address account,
        uint256 paymentAmount,
        bytes16 authorizationId
    ) internal returns (uint256 sentAmount, uint16 appliedCashbackRate) {
        address distributor = _cashbackDistributor;
        if (_cashbackEnabled && distributor != address(0)) {
            bool success;
            uint256 cashbackNonce;
            appliedCashbackRate = _cashbackRateInPermil;
            uint256 cashbackAmount = calculateCashback(paymentAmount, appliedCashbackRate);
            (success, sentAmount, cashbackNonce) = ICashbackDistributor(distributor).sendCashback(
                _token,
                ICashbackDistributorTypes.CashbackKind.CardPayment,
                authorizationId,
                account,
                cashbackAmount
            );
            _cashbacks[authorizationId].lastCashbackNonce = cashbackNonce;
            if (success) {
                emit SendCashbackSuccess(distributor, sentAmount, cashbackNonce);
            } else {
                emit SendCashbackFailure(distributor, cashbackAmount, cashbackNonce);
                appliedCashbackRate = 0;
            }
        }
    }

    function revokeCashbackInternal(bytes16 authorizationId, uint256 amount) internal {
        address distributor = _cashbackDistributor;
        uint256 cashbackNonce = _cashbacks[authorizationId].lastCashbackNonce;
        if (cashbackNonce != 0 && distributor != address(0)) {
            if (ICashbackDistributor(distributor).revokeCashback(cashbackNonce, amount)) {
                emit RevokeCashbackSuccess(distributor, amount, cashbackNonce);
            } else {
                emit RevokeCashbackFailure(distributor, amount, cashbackNonce);
            }
        }
    }

    function increaseCashbackInternal(
        bytes16 authorizationId,
        uint256 amount
    ) internal returns (uint256 sentAmount) {
        address distributor = _cashbackDistributor;
        uint256 cashbackNonce = _cashbacks[authorizationId].lastCashbackNonce;
        if (cashbackNonce != 0 && distributor != address(0)) {
            bool success;
            (success, sentAmount) = ICashbackDistributor(distributor).increaseCashback(cashbackNonce, amount);
            if (success) {
                emit IncreaseCashbackSuccess(distributor, sentAmount, cashbackNonce);
            } else {
                emit IncreaseCashbackFailure(distributor, amount, cashbackNonce);
            }
        }
    }

    function requireCashOutAccount() internal view returns (address account) {
        account = _cashOutAccount;
        if (account == address(0)) {
            revert ZeroCashOutAccount();
        }
    }

    function calculateCashback(uint256 amount, uint256 cashbackRateInPermil) internal pure returns (uint256) {
        return amount * cashbackRateInPermil / 1000;
    }
}
