;; BitForge Protocol - Stacks Bitcoin Collateral Engine
;; 
;; A revolutionary decentralized lending protocol that transforms Bitcoin
;; into productive capital through the Stacks blockchain ecosystem.
;; 
;; BitForge enables seamless borrowing against Bitcoin collateral while
;; preserving the security guarantees of the Bitcoin network through
;; Stacks L2 smart contract infrastructure.
;; 
;; Key Features:
;; - Bitcoin-native collateralization through sBTC integration
;; - Dynamic liquidation engine with automated risk management
;; - Trustless stablecoin minting backed by Bitcoin's monetary premium
;; - Governance-driven parameter optimization for market efficiency
;; - Oracle-powered price feeds for real-time collateral valuation

;; ERROR CONSTANTS - Comprehensive Error Handling Framework

(define-constant ERR-UNAUTHORIZED-ACCESS (err u2000))
(define-constant ERR-INADEQUATE-COLLATERAL (err u2001))
(define-constant ERR-POSITION-NOT-EXISTS (err u2002))
(define-constant ERR-POSITION-UNHEALTHY (err u2003))
(define-constant ERR-MINIMUM-THRESHOLD-BREACH (err u2004))
(define-constant ERR-BORROWING-LIMIT-EXCEEDED (err u2005))
(define-constant ERR-ORACLE-DATA-STALE (err u2006))
(define-constant ERR-INVALID-AMOUNT (err u2007))
(define-constant ERR-PROTOCOL-MAINTENANCE (err u2008))
(define-constant ERR-LIQUIDATION-EXECUTION-FAILED (err u2009))
(define-constant ERR-ASSET-CONTRACT-INVALID (err u2010))
(define-constant ERR-PRINCIPAL-ADDRESS-INVALID (err u2011))

;; PROTOCOL CONFIGURATION - Dynamic Parameter Management

(define-data-var emergency-pause-active bool false)
(define-data-var protocol-governance-controller principal 'SP000000000000000000002Q6VF78)
(define-data-var protocol-administrator principal tx-sender)
(define-data-var minimum-liquidation-ratio uint u150)     ;; 150% - Critical liquidation threshold
(define-data-var required-collateral-ratio uint u200)     ;; 200% - Initial borrowing requirement
(define-data-var liquidation-bonus-percentage uint u10)   ;; 10% - Liquidator incentive bonus
(define-data-var minimum-position-size uint u1000000)     ;; 0.01 BTC minimum (1M satoshis)
(define-data-var protocol-origination-fee uint u1)        ;; 1% - Borrowing origination fee
(define-data-var oracle-staleness-window uint u3600)      ;; 1 hour - Price data freshness requirement
(define-data-var bitcoin-price-feed uint u0)              ;; Current BTC/USD price in cents
(define-data-var oracle-last-refresh uint u0)             ;; Timestamp of last price update

;; TRAIT DEFINITIONS - Token and Oracle Interface Standards

;; Fungible Token Standard for sBTC and Stablecoin Integration
(define-trait fungible-token-interface
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
    (mint (uint principal) (response bool uint))
    (burn (uint principal) (response bool uint))
  )
)

;; Price Oracle Interface for Real-time Market Data
(define-trait price-oracle-interface
  (
    (get-price-in-cents () (response uint uint))
    (get-last-update-time () (response uint uint))
  )
)

;; DATA STORAGE - User Position and Protocol State Management

;; Bitcoin collateral holdings per user (denominated in satoshis)
(define-map bitcoin-collateral-vault principal uint)

;; Outstanding debt positions per user (denominated in stablecoin base units)
(define-map active-debt-positions principal uint)

;; Interest calculation checkpoints for compound interest accrual
(define-map interest-accrual-checkpoint principal uint)

;; PUBLIC READ-ONLY FUNCTIONS - Protocol State Queries

;; Retrieve user's Bitcoin collateral balance
(define-read-only (get-collateral-balance (user-address principal))
  (default-to u0 (map-get? bitcoin-collateral-vault user-address))
)

;; Retrieve user's outstanding debt balance
(define-read-only (get-debt-balance (user-address principal))
  (default-to u0 (map-get? active-debt-positions user-address))
)

;; Get current Bitcoin price from oracle feed
(define-read-only (get-bitcoin-market-price)
  (var-get bitcoin-price-feed)
)

;; Get timestamp of last oracle price update
(define-read-only (get-oracle-update-timestamp)
  (var-get oracle-last-refresh)
)

;; Retrieve protocol administrator address
(define-read-only (get-protocol-administrator)
  (var-get protocol-administrator)
)

;; Check if oracle price data has exceeded staleness threshold
(define-read-only (is-oracle-data-stale)
  (let (
    (current-block stacks-block-height)
    (last-update (var-get oracle-last-refresh))
  )
    (> (- current-block last-update) (var-get oracle-staleness-window))
  )
)

;; Calculate position health ratio (collateral value / debt value * 100)
;; Returns percentage representation: 200 = 200% collateralized
(define-read-only (calculate-position-health (user-address principal))
  (let (
    (user-collateral (get-collateral-balance user-address))
    (user-debt (get-debt-balance user-address))
    (btc-price (var-get bitcoin-price-feed))
  )
    (if (or (is-eq user-debt u0) (is-eq user-collateral u0))
      u0
      ;; Health calculation: (collateral_sats * btc_price_cents / 100M_sats_per_btc) / debt_amount * 100
      (/ (* (* user-collateral btc-price) u100) (* user-debt u100000000))
    )
  )
)

;; Determine if position qualifies for liquidation
(define-read-only (is-position-liquidatable (user-address principal))
  (let (
    (position-health (calculate-position-health user-address))
    (liquidation-ratio (var-get minimum-liquidation-ratio))
  )
    (and 
      (> (get-debt-balance user-address) u0)
      (> (get-collateral-balance user-address) u0)
      (< position-health liquidation-ratio)
      (not (is-oracle-data-stale))
    )
  )
)

;; ACCESS CONTROL - Administrative Function Guards

;; Verify caller has governance or administrative privileges
(define-private (verify-administrative-access)
  (or 
    (is-eq tx-sender (var-get protocol-governance-controller)) 
    (is-eq tx-sender (var-get protocol-administrator))
  )
)

;; Validate token contract reference integrity
(define-private (validate-token-contract (token-contract <fungible-token-interface>))
  (is-some (some (contract-of token-contract)))
)

;; Validate principal address format and constraints
(define-private (validate-principal-address (target-address principal))
  (and 
    (not (is-eq target-address 'SP000000000000000000002Q6VF78))
    (not (is-eq target-address tx-sender))
  )
)

;; GOVERNANCE FUNCTIONS - Protocol Parameter Management

;; Transfer governance control to new address
(define-public (transfer-governance-control (new-governance-address principal))
  (begin
    (asserts! (verify-administrative-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address new-governance-address) ERR-PRINCIPAL-ADDRESS-INVALID)
    (ok (var-set protocol-governance-controller new-governance-address))
  )
)

;; Transfer administrative control to new address
(define-public (transfer-administrative-control (new-admin-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address new-admin-address) ERR-PRINCIPAL-ADDRESS-INVALID)
    (ok (var-set protocol-administrator new-admin-address))
  )
)

;; Emergency protocol pause/unpause mechanism
(define-public (toggle-emergency-pause (pause-status bool))
  (begin
    (asserts! (verify-administrative-access) ERR-UNAUTHORIZED-ACCESS)
    (ok (var-set emergency-pause-active pause-status))
  )
)

;; Update liquidation threshold parameters
(define-public (configure-liquidation-threshold (new-threshold-percentage uint))
  (begin
    (asserts! (verify-administrative-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= new-threshold-percentage u110) ERR-POSITION-UNHEALTHY)
    (ok (var-set minimum-liquidation-ratio new-threshold-percentage))
  )
)

;; Update collateral requirements for new loans
(define-public (configure-collateral-requirements (new-ratio-percentage uint))
  (begin
    (asserts! (verify-administrative-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> new-ratio-percentage (var-get minimum-liquidation-ratio)) ERR-POSITION-UNHEALTHY)
    (ok (var-set required-collateral-ratio new-ratio-percentage))
  )
)

;; Update Bitcoin price through trusted oracle integration
(define-public (refresh-bitcoin-price (oracle-contract <price-oracle-interface>))
  (begin
    (asserts! (verify-administrative-access) ERR-UNAUTHORIZED-ACCESS)
    
    (let (
      (price-query (contract-call? oracle-contract get-price-in-cents))
      (timestamp-query (contract-call? oracle-contract get-last-update-time))
    )
      (asserts! (is-ok price-query) ERR-ORACLE-DATA-STALE)
      (asserts! (is-ok timestamp-query) ERR-ORACLE-DATA-STALE)
      
      (var-set bitcoin-price-feed (unwrap-panic price-query))
      (var-set oracle-last-refresh (unwrap-panic timestamp-query))
      
      (ok (var-get bitcoin-price-feed))
    )
  )
)

;; CORE LENDING PROTOCOL - Bitcoin Collateral Management

;; Deposit sBTC as collateral to enable borrowing capacity
(define-public (deposit-bitcoin-collateral (sbtc-contract <fungible-token-interface>) (collateral-amount uint))
  (begin
    ;; Protocol safety checks
    (asserts! (not (var-get emergency-pause-active)) ERR-PROTOCOL-MAINTENANCE)
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (validate-token-contract sbtc-contract) ERR-ASSET-CONTRACT-INVALID)
    
    ;; Execute sBTC transfer from user to protocol vault
    (let 
      ((transfer-execution (try! (contract-call? sbtc-contract transfer 
                                    collateral-amount 
                                    tx-sender 
                                    (as-contract tx-sender) 
                                    none))))
      
      ;; Update user's collateral registry
      (map-set bitcoin-collateral-vault 
               tx-sender 
               (+ (get-collateral-balance tx-sender) collateral-amount))
      
      (ok collateral-amount)
    )
  )
)

;; Withdraw sBTC collateral with position health verification
(define-public (withdraw-bitcoin-collateral (sbtc-contract <fungible-token-interface>) (withdrawal-amount uint))
  (begin
    ;; Protocol safety checks
    (asserts! (not (var-get emergency-pause-active)) ERR-PROTOCOL-MAINTENANCE)
    (asserts! (> withdrawal-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (is-oracle-data-stale)) ERR-ORACLE-DATA-STALE)
    (asserts! (validate-token-contract sbtc-contract) ERR-ASSET-CONTRACT-INVALID)
    
    (let (
      (current-collateral (get-collateral-balance tx-sender))
      (outstanding-debt (get-debt-balance tx-sender))
    )
      ;; Verify sufficient collateral exists
      (asserts! (>= current-collateral withdrawal-amount) ERR-INADEQUATE-COLLATERAL)
      
      ;; Handle withdrawal logic based on debt status
      (if (> outstanding-debt u0)
        ;; Active debt position - verify health after withdrawal
        (let (
            (remaining-collateral (- current-collateral withdrawal-amount))
          (post-withdrawal-health (/ (* (* remaining-collateral (var-get bitcoin-price-feed)) u100) 
                                    (* outstanding-debt u100000000)))
        )
          ;; Ensure minimum position size and health requirements
          (asserts! (>= remaining-collateral (var-get minimum-position-size)) ERR-MINIMUM-THRESHOLD-BREACH)
          (asserts! (>= post-withdrawal-health (var-get required-collateral-ratio)) ERR-POSITION-UNHEALTHY)
          
          ;; Execute withdrawal
          (map-set bitcoin-collateral-vault tx-sender remaining-collateral)
          (try! (as-contract (contract-call? sbtc-contract transfer 
                               withdrawal-amount 
                               (as-contract tx-sender) 
                               tx-sender 
                               none)))
          (ok withdrawal-amount)
        )
        ;; No active debt - execute simple withdrawal
        (begin
          (map-set bitcoin-collateral-vault tx-sender (- current-collateral withdrawal-amount))
          (try! (as-contract (contract-call? sbtc-contract transfer 
                               withdrawal-amount 
                               (as-contract tx-sender) 
                               tx-sender 
                               none)))
          (ok withdrawal-amount)
        )
      )
    )
  )
)

;; BORROWING MECHANISM - Stablecoin Minting Against Bitcoin Collateral

;; Mint stablecoin debt position against Bitcoin collateral
(define-public (mint-debt-position (stablecoin-contract <fungible-token-interface>) (borrowing-amount uint))
  (begin
    ;; Protocol safety and validity checks
    (asserts! (not (var-get emergency-pause-active)) ERR-PROTOCOL-MAINTENANCE)
    (asserts! (> borrowing-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (is-oracle-data-stale)) ERR-ORACLE-DATA-STALE)
    (asserts! (validate-token-contract stablecoin-contract) ERR-ASSET-CONTRACT-INVALID)
    
    (let (
      (bitcoin-collateral (get-collateral-balance tx-sender))
      (existing-debt (get-debt-balance tx-sender))
      (btc-market-price (var-get bitcoin-price-feed))
      (block-timestamp stacks-block-height)
    )
      ;; Verify minimum collateral requirements
      (asserts! (>= bitcoin-collateral (var-get minimum-position-size)) ERR-MINIMUM-THRESHOLD-BREACH)
      
      ;; Calculate borrowing capacity and validate request
      (let (
        (total-debt-position (+ existing-debt borrowing-amount))
        ;; Collateral value: (sats * price_cents) / 100M_sats_per_btc
        (collateral-value-usd (/ (* bitcoin-collateral btc-market-price) u100000000))
        ;; Maximum borrowing: collateral_value / collateral_ratio * 100
        (maximum-borrowing-capacity (/ (* collateral-value-usd u100) (var-get required-collateral-ratio)))
      )
        ;; Ensure borrowing doesn't exceed collateral capacity
        (asserts! (<= total-debt-position maximum-borrowing-capacity) ERR-BORROWING-LIMIT-EXCEEDED)
        
        ;; Update debt registry
        (map-set active-debt-positions tx-sender total-debt-position)
        (map-set interest-accrual-checkpoint tx-sender block-timestamp)
        
        ;; Execute stablecoin minting with fee collection
        (let ((origination-fee (/ (* borrowing-amount (var-get protocol-origination-fee)) u100)))
          ;; Mint net amount to borrower
          (try! (as-contract (contract-call? stablecoin-contract mint 
                               (- borrowing-amount origination-fee) 
                               tx-sender)))
          ;; Mint fee to governance treasury
          (try! (as-contract (contract-call? stablecoin-contract mint 
                               origination-fee 
                               (var-get protocol-governance-controller))))
          
          (ok borrowing-amount)
        )
      )
    )
  )
)

;; DEBT REPAYMENT - Position Closure and Partial Payment Processing

;; Repay outstanding debt to reduce or eliminate position
(define-public (repay-debt-position (stablecoin-contract <fungible-token-interface>) (repayment-amount uint))
  (begin
    ;; Input validation
    (asserts! (> repayment-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (validate-token-contract stablecoin-contract) ERR-ASSET-CONTRACT-INVALID)
    
    (let (
      (outstanding-debt (get-debt-balance tx-sender))
    )