# 🐷 PorketOption - Decentralized Savings & Investment Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Starknet](https://img.shields.io/badge/Starknet-2.12-orange.svg)](https://starknet.io)
[![Cairo](https://img.shields.io/badge/Cairo-2.0-red.svg)](https://cairo-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

PorketOption is a revolutionary mobile application that combines the power of decentralized finance (DeFi) with user-friendly savings and investment management. Built on Starknet with Cairo smart contracts, it offers multiple savings options with competitive interest rates while maintaining complete transparency and security.

## 🚀 Key Features

### 💰 Comprehensive Savings Ecosystem
- **Embedded Wallet**: Seamless onboarding with email-based wallet creation
- **Flexi Save**: 18% APY with instant liquidity and automated recurring deposits
- **Lock Save**: 5.5% to 12.5% APY based on lock duration (10-365 days) with automatic payouts
- **Goal Save**: Purpose-driven savings with categories, progress tracking, and achievement rewards
- **Group Save**: Social savings with public/private groups, leaderboards, and competitive challenges

### 🌍 Global Financial Access
- **Global Accessibility**: Multi-currency support (NGN, USD, EUR) with onramp/offramp integration
- **Multi-language Support**: Localized experience for global users
- **Cross-Chain Deposits**: Accept funds from Ethereum, Polygon, BSC, and other major networks

### ⚡ Advanced Financial Technology
- **Dynamic Interest Rates**: Real-time calculation based on market conditions and lock duration
- **Automated Smart Contracts**: Built on Starknet with Cairo for secure, transparent operations
- **Real-time Updates**: Live balance tracking and instant transaction confirmation

### 🎮 Gamified User Experience
- **Gamified Experience**: Streaks, achievements, and social features to encourage consistent saving
- **Progress Tracking**: Visual progress indicators for all savings goals
- **Achievement System**: Badges and rewards for financial milestones
- **Social Leaderboards**: Competitive features to motivate users

### 🔒 Security & User Experience
- **Gasless Transactions**: AVNU Paymaster integration for seamless, gas-free user experience
- **Secure Transactions**: Enterprise-grade security with transparent fee structure
- **Emergency Controls**: Owner-controlled pause/unpause functionality for added security
- **Transparent Operations**: All transactions visible on-chain with clear audit trails

## 🛠️ Technology Stack

### Frontend
- **Flutter 3.0+**: Cross-platform mobile development
- **Dart**: Programming language
- **Stacked Architecture**: MVVM architecture pattern
- **Firebase**: Authentication and backend services
- **Fl Chart**: Beautiful data visualization

### Blockchain
- **Starknet**: Layer 2 scaling solution for Ethereum
- **Cairo 2.0**: Smart contract programming language
- **OpenZeppelin**: Secure contract templates and components
- **USDC Integration**: Stablecoin support for deposits

### Development Tools
- **Golden Toolkit**: Visual regression testing
- **SnForge**: Starknet contract testing framework
- **Build Runner**: Code generation
- **Mockito**: Testing utilities

## 📊 Smart Contract Architecture

### Core Contracts
- **SavingsVault**: Main contract handling all savings operations
- **AutomationScheduler**: Automated interest distribution and maturity handling

### Savings Types
1. **Flexi Savings**: 4% APY, instant withdrawals
2. **Lock Savings**: 4-15% APY based on duration (30-365 days)
3. **Goal Savings**: 6% APY, target-based savings
4. **Group Savings**: 8% APY, collaborative saving pools

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Starknet/Cairo development environment
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Devsol01/PorketOption.git
   cd PorketOption
   ```

2. **Setup Mobile App**
   ```bash
   cd mobile_app
   flutter pub get
   ```

3. **Setup Smart Contracts**
   ```bash
   cd contract
   scarb build
   ```

### Running the Application

**Mobile App:**
```bash
cd mobile_app
flutter run
```

**Contract Testing:**
```bash
cd contract
snforge test
```

**UI Testing:**
```bash
cd mobile_app
flutter test --update-goldens
```

## 🧪 Testing

### Smart Contract Tests
```bash
cd contract
snforge test<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 28 56" src="https://github.com/user-attachments/assets/b7393cc0-bfe1-4713-8385-3a69cb962249" />
<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 28 41" src="https://github.com/user-attachments/assets/fe3d7b4d-55d0-402c-8a6d-7a8519948c0c" />
<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 28 25" src="https://github.com/user-attachments/assets/9ab155a3-3878-4207-ab0c-68e1eca2f922" />
<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 28 08" src="https://github.com/user-attachments/assets/c11554f1-b338-4164-89d9-c58f2b9f4c94" />
<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 27 45" src="https://github.com/user-attachments/assets/e1246e3a-d840-4a6c-be41-4d149b0b17d3" />
<img width="400" height="843" alt="Screenshot 2025-10-17 at 23 27 45" src="https://github.com/user-attachments/assets/2bea205d-ed11-4ad5-bcab-2d1f228bc1ff" />



### Innovation
- **First multi-type savings platform** on Starknet with flexible interest rates
- **Social savings feature** enabling group financial goals
- **Streak-based rewards** system to encourage consistent saving habits

### Technical Excellence
- **Gas-optimized Cairo contracts** with efficient storage patterns
- **Real-time interest calculation** without oracle dependency
- **Comprehensive test coverage** with 100+ test cases

### User Experience
- **Intuitive mobile interface** with smooth animations
- **Zero learning curve** for traditional banking users
- **Instant transaction feedback** with real-time updates

## 🔮 Future Roadmap

- [ ] **Cross-chain integration** with multiple L2 solutions
- [ ] **NFT-based achievements** for savings milestones
- [ ] **AI-powered savings recommendations**
- [ ] **In-app investment options** beyond savings
- [ ] **Multi-language support** for global adoption
- [ ] **Advanced analytics dashboard** for users

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
