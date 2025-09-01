# BitForge Protocol

[![Stacks](https://img.shields.io/badge/Stacks-2.0-blue)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-orange)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A revolutionary decentralized lending protocol that transforms Bitcoin into productive capital through the Stacks blockchain ecosystem.

## Overview

BitForge Protocol is a sophisticated DeFi lending platform built on Stacks that enables seamless borrowing against Bitcoin collateral while preserving the security guarantees of the Bitcoin network through Stacks L2 smart contract infrastructure. The protocol facilitates trustless stablecoin minting backed by Bitcoin's monetary premium with automated risk management and governance-driven parameter optimization.

## Key Features

- **🔗 Bitcoin-Native Collateralization**: Direct integration with sBTC for seamless Bitcoin collateral management
- **⚡ Dynamic Liquidation Engine**: Automated risk management system with real-time position monitoring
- **🏦 Trustless Stablecoin Minting**: Algorithmic debt position creation backed by Bitcoin's monetary premium
- **🏛️ Governance-Driven Parameters**: Community-controlled protocol optimization for market efficiency
- **📊 Oracle-Powered Price Feeds**: Real-time collateral valuation with staleness protection

## Architecture

### Core Components

#### 1. Collateral Management System

- **sBTC Integration**: Native Bitcoin representation on Stacks
- **Position Tracking**: Real-time monitoring of collateral-to-debt ratios
- **Health Calculations**: Dynamic position health assessment

#### 2. Liquidation Engine

- **Automated Risk Management**: Continuous monitoring of undercollateralized positions
- **Liquidator Incentives**: Built-in bonus system for liquidation participants
- **Partial/Full Liquidations**: Flexible liquidation mechanics based on position size

#### 3. Oracle Integration

- **Price Feed Management**: Real-time Bitcoin price updates
- **Staleness Protection**: Automatic rejection of outdated price data
- **Governance Control**: Administrative oversight of oracle operations

#### 4. Governance Framework

- **Parameter Adjustment**: Dynamic protocol configuration
- **Emergency Controls**: Circuit breakers for protocol safety
- **Access Management**: Multi-tier administrative privileges

## Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Minimum Liquidation Ratio | 150% | Critical threshold for position liquidation |
| Required Collateral Ratio | 200% | Initial borrowing requirement |
| Liquidation Bonus | 10% | Incentive for liquidators |
| Minimum Position Size | 0.01 BTC | Smallest allowed collateral deposit |
| Origination Fee | 1% | Protocol fee on new debt positions |
| Oracle Staleness Window | 1 hour | Maximum age for valid price data |

## Smart Contract Interface

### Core Functions

#### Collateral Management

```clarity
;; Deposit sBTC as collateral
(deposit-bitcoin-collateral (sbtc-contract <fungible-token-interface>) (collateral-amount uint))

;; Withdraw collateral with health checks
(withdraw-bitcoin-collateral (sbtc-contract <fungible-token-interface>) (withdrawal-amount uint))
```

#### Debt Operations

```clarity
;; Mint stablecoin against collateral
(mint-debt-position (stablecoin-contract <fungible-token-interface>) (borrowing-amount uint))

;; Repay outstanding debt
(repay-debt-position (stablecoin-contract <fungible-token-interface>) (repayment-amount uint))
```

#### Liquidation System

```clarity
;; Execute position liquidation
(execute-position-liquidation 
  (target-user principal) 
  (sbtc-contract <fungible-token-interface>) 
  (stablecoin-contract <fungible-token-interface>))
```

### Read-Only Functions

#### Position Queries

```clarity
;; Get user collateral balance
(get-collateral-balance (user-address principal))

;; Get user debt balance
(get-debt-balance (user-address principal))

;; Calculate position health ratio
(calculate-position-health (user-address principal))

;; Check liquidation eligibility
(is-position-liquidatable (user-address principal))
```

#### Protocol State

```clarity
;; Get current Bitcoin price
(get-bitcoin-market-price)

;; Check oracle data freshness
(is-oracle-data-stale)

;; Get protocol administrator
(get-protocol-administrator)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 2000 | ERR-UNAUTHORIZED-ACCESS | Insufficient privileges for operation |
| 2001 | ERR-INADEQUATE-COLLATERAL | Insufficient collateral for operation |
| 2002 | ERR-POSITION-NOT-EXISTS | No active debt position found |
| 2003 | ERR-POSITION-UNHEALTHY | Position below health threshold |
| 2004 | ERR-MINIMUM-THRESHOLD-BREACH | Below minimum position requirements |
| 2005 | ERR-BORROWING-LIMIT-EXCEEDED | Exceeds maximum borrowing capacity |
| 2006 | ERR-ORACLE-DATA-STALE | Price data exceeds staleness window |
| 2007 | ERR-INVALID-AMOUNT | Invalid amount parameter |
| 2008 | ERR-PROTOCOL-MAINTENANCE | Protocol in emergency pause mode |
| 2009 | ERR-LIQUIDATION-EXECUTION-FAILED | Liquidation conditions not met |
| 2010 | ERR-ASSET-CONTRACT-INVALID | Invalid token contract reference |
| 2011 | ERR-PRINCIPAL-ADDRESS-INVALID | Invalid principal address format |

## Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.0+
- [Node.js](https://nodejs.org/) v16+
- [Stacks CLI](https://docs.stacks.co/understand-stacks/command-line-interface)

### Installation

```bash
# Clone the repository
git clone https://github.com/ayo-victoria/bitforge.git
cd bitforge

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

### Project Structure

```text
bitforge/
├── contracts/
│   └── bitforge.clar          # Main protocol contract
├── tests/
│   └── bitforge.test.ts       # Comprehensive test suite
├── settings/
│   ├── Devnet.toml           # Development network config
│   ├── Testnet.toml          # Testnet configuration
│   └── Mainnet.toml          # Mainnet configuration
├── Clarinet.toml             # Clarinet project configuration
├── package.json              # Node.js dependencies
├── tsconfig.json             # TypeScript configuration
└── vitest.config.js          # Test configuration
```

## Testing

The protocol includes a comprehensive test suite covering:

- **Unit Tests**: Individual function validation
- **Integration Tests**: Multi-function workflow testing
- **Edge Cases**: Boundary condition testing
- **Security Tests**: Access control and safety mechanism validation

```bash
# Run all tests
npm test

# Run contract checks
clarinet check

# Run specific test file
npx vitest tests/bitforge.test.ts
```

## Deployment

### Local Development

```bash
# Start local Stacks blockchain
clarinet devnet start

# Deploy contracts
clarinet deploy --network devnet
```

### Testnet Deployment

```bash
# Configure testnet settings
clarinet deploy --network testnet
```

### Mainnet Deployment

```bash
# Configure mainnet settings (requires careful review)
clarinet deploy --network mainnet
```

## Security Considerations

### Risk Management

- **Collateralization Requirements**: Minimum 200% collateral ratio for new positions
- **Liquidation Thresholds**: Automatic liquidation at 150% health ratio
- **Oracle Safeguards**: Staleness checks prevent stale price exploitation
- **Emergency Controls**: Protocol-wide pause mechanism for critical situations

### Access Controls

- **Governance Layer**: Multi-signature control for parameter updates
- **Administrative Functions**: Restricted access to critical operations
- **Validation Checks**: Comprehensive input validation and error handling

### Audit Status

*This protocol is under development. A comprehensive security audit is recommended before mainnet deployment.*

## Governance

The BitForge Protocol implements a robust governance framework with the following features:

- **Parameter Adjustment**: Community-driven optimization of protocol parameters
- **Emergency Response**: Circuit breakers for protocol safety
- **Upgrade Mechanisms**: Controlled protocol evolution
- **Treasury Management**: Protocol fee distribution and management

## Economic Model

### Fee Structure

- **Origination Fee**: 1% on new debt positions
- **Liquidation Bonus**: 10% incentive for liquidators
- **No Ongoing Interest**: Zero-fee borrowing model (fees collected upfront)

### Tokenomics

- **Collateral Asset**: sBTC (Stacks Bitcoin)
- **Debt Asset**: Protocol stablecoin
- **Yield Generation**: Protocol fees distributed to governance token holders

## Roadmap

- **Phase 1**: Core protocol deployment and testing
- **Phase 2**: Advanced liquidation mechanisms and partial liquidations
- **Phase 3**: Multi-collateral support and yield farming
- **Phase 4**: Cross-chain expansion and additional Bitcoin L2 integrations

## Contributing

We welcome contributions to the BitForge Protocol. Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our development process.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Stacks Foundation](https://stacks.org/) for the blockchain infrastructure
- [Clarity Language](https://clarity-lang.org/) for smart contract capabilities
- [sBTC](https://sbtc.tech/) for Bitcoin representation on Stacks
- The broader DeFi community for inspiration and innovation

---

Built with ❤️ on Stacks • Powered by Bitcoin
