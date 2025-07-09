# Shroudinger DNS Privacy App

A privacy-first macOS DNS blocklist and encryption application that provides system-wide ad blocking and DNS privacy protection without logging user data.

## 🔒 Privacy-First Architecture

- **No User Data Logging**: Zero DNS query logging or domain name storage
- **In-Memory Processing**: All data structures loaded at startup, discarded on shutdown
- **Encrypted DNS**: Support for DoT (DNS over TLS), DoH (DNS over HTTPS), and DoQ (DNS over QUIC)
- **Local Filtering**: All DNS filtering happens locally without external analytics

## 🏗️ Monorepo Structure

```
shroudinger-dns/
├── frontend/           # Swift macOS Application
│   ├── ShroudingerApp/    # Main GUI app
│   ├── ShroudingerExtension/ # NetworkExtension
│   └── Shared/            # Shared Swift components
├── backend/            # Go Backend Services
│   ├── cmd/               # Service entry points
│   ├── internal/          # Internal packages
│   └── pkg/               # Public packages
├── middleware/         # Go Middleware (App Logic)
├── shared/             # Cross-language resources
├── docs/               # Documentation
└── scripts/            # Build and deployment scripts
```

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+ (for development)
- Xcode 15+
- Go 1.21+
- Homebrew

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd shroudinger-dns
   ```

2. **Set up development environment**
   ```bash
   ./scripts/setup-dev.sh
   ```

3. **Build all components**
   ```bash
   make build
   ```

4. **Run tests**
   ```bash
   make test
   ```

5. **Start development services**
   ```bash
   make dev
   ```

## 🔧 Development Commands

- `make build` - Build all components
- `make test` - Run all tests
- `make dev` - Start development services
- `make dev-stop` - Stop development services
- `make privacy-audit` - Run privacy compliance audit
- `make lint` - Run code linters
- `make clean` - Clean build artifacts

## 📱 Components

### Frontend (Swift)
- **ShroudingerApp**: Main macOS application with SwiftUI interface
- **ShroudingerExtension**: NetworkExtension for system-wide DNS interception
- **Shared**: Common Swift components and data structures

### Backend (Go)
- **api-server**: Main API server (port 8080)
- **blocklist-service**: Blocklist management service (port 8081)
- **dns-service**: DNS resolution service (port 8082)

### Middleware (Go)
- **middleware**: App-Extension coordination service (port 8083)

## 🔒 Privacy Guarantees

1. **No DNS Query Logging**: DNS queries are processed and immediately discarded
2. **No Domain Name Storage**: Domain names are never persisted to disk
3. **No User Tracking**: No analytics, telemetry, or user behavior tracking
4. **In-Memory Only**: All processing happens in memory without persistence
5. **Anonymous Caching**: DNS responses cached with hashed keys, no domain storage

## 🎯 Key Features

- **System-Wide DNS Filtering**: Blocks ads and trackers for all applications
- **Encrypted DNS Support**: DoT, DoH, and DoQ protocols
- **High-Performance Filtering**: Sub-millisecond domain lookups using Trie data structures
- **Multiple Blocklist Formats**: Support for hosts files, Adblock Plus, and domain lists
- **Real-Time Statistics**: Runtime counters without user data retention
- **Menu Bar Integration**: Easy access and control from the macOS menu bar

## 🧪 Testing

### Unit Tests
```bash
make test
```

### Privacy Audit
```bash
make privacy-audit
```

### Performance Tests
```bash
cd backend && go test -bench=. ./...
```

## 📊 Performance Targets

- **DNS Query Lookup**: <1ms (Trie + Bloom filter)
- **DNS Resolution**: <5ms (encrypted DNS)
- **Startup Time**: <5 seconds
- **Memory Usage**: <150MB total
- **Cache Hit Rate**: >85%

## 🔧 Configuration

Configuration files are located in `shared/configs/`:
- `development.yaml` - Development settings
- `production.yaml` - Production settings

## 📚 Documentation

- [Architecture Documentation](docs/architecture/)
- [API Documentation](docs/api/)
- [Development Guide](docs/development/)

## 🤝 Contributing

1. Read the privacy-first principles in [docs/privacy-policy.md](docs/privacy-policy.md)
2. Ensure all changes pass the privacy audit: `make privacy-audit`
3. Follow the coding standards and run linters: `make lint`
4. Write tests for new functionality: `make test`

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔐 Security

For security issues, please contact the development team privately. Do not open public issues for security vulnerabilities.

## 🏆 Acknowledgments

- Inspired by privacy-focused DNS solutions like Pi-hole and AdGuard
- Built on Apple's NetworkExtension framework
- Uses encrypted DNS protocols for enhanced privacy