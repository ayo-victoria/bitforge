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