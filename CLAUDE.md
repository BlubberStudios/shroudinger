# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shroudinger is a privacy-first macOS DNS blocklist and encryption application that provides system-wide ad blocking and DNS privacy protection. It's a monorepo with Swift (frontend) and Go (backend/middleware) components.

## Development Commands

### Build Commands
- `make build` - Build all components (Swift frontend, Go backend/middleware)
- `make build-prod` - Create production build with optimizations
- `make clean` - Clean build artifacts

### Development Workflow
- `make dev-setup` - Set up development environment (install tools, dependencies)
- `make dev` - Start all development services (API server:8080, blocklist:8081, DNS:8082, middleware:8083)
- `make dev-stop` - Stop all development services
- `make health` - Check if all services are running

### Testing
- `make test` - Run all tests (Swift + Go)
- `make privacy-audit` - Run privacy compliance audit
- `make lint` - Run linters (golangci-lint for Go)

### Individual Component Commands
- **Swift Frontend**: `cd frontend && xcodebuild -project Shroudinger.xcodeproj -scheme Shroudinger`
- **Go Backend**: `cd backend && go run ./cmd/api-server` (or blocklist-service, dns-service)
- **Go Middleware**: `cd middleware && go run ./cmd/middleware`
- **Go Tests**: `cd backend && go test -v ./...` or `cd middleware && go test -v ./...`

## Architecture

### Monorepo Structure
```
shroudinger/
├── frontend/           # Swift macOS Application
│   └── Shroudinger/       # Xcode project
│       ├── Shroudinger/   # Main GUI app (SwiftUI)
│       ├── ShroudingerExtension/ # NetworkExtension (NEDNSProxyProvider)
│       ├── ShroudingerTests/ # Unit tests
│       └── ShroudingerUITests/ # UI tests
├── backend/            # Go Backend Services
│   ├── cmd/               # Service entry points (api-server, blocklist-service, dns-service)
│   └── internal/models/   # Data models (blocklist.go, dns.go)
├── middleware/         # Go Middleware (App-Extension coordination)
├── Blocklist/          # Blocklist management (Swift)
├── docs/               # Documentation and architecture
└── scripts/            # Build and development scripts
```

### Multi-Process Architecture
The application follows a multi-process architecture with clear separation of concerns:
- **NEDNSProxyProvider**: System-wide DNS interception (captures all DNS traffic from every application)
- **Menu Bar Interface**: Immediate access and real-time feedback
- **Main Application Process**: Configuration, blocklist management, coordination with network extension
- **System Extension Approval**: Requires user approval through macOS System Preferences

### Service Architecture
- **API Server** (port 8080): Main REST API for app communication
- **Blocklist Service** (port 8081): Manages domain blocklist updates and queries
- **DNS Service** (port 8082): Handles encrypted DNS resolution (DoT, DoH, DoQ)
- **Middleware** (port 8083): Coordinates between macOS app and NetworkExtension

### Technology Stack
- **Swift 5.9+**: SwiftUI for GUI, NetworkExtension for system DNS interception, async/await structured concurrency
- **Go 1.21+**: Backend services using Gin framework v1.9.1
- **Data Structures**: Trie (prefix tree), Bloom filters, Hash tables for microsecond domain lookups
- **DNS Protocols**: DoT (DNS over TLS), DoH (DNS over HTTPS), DoQ (DNS over QUIC)
- **Frameworks**: MenuBarExtra, AppKit, Combine, Network.framework, CryptoKit
- **Build System**: Make-based build system with comprehensive targets

## Privacy-First Design

This application is designed with strict privacy principles:
- **No DNS query logging**: All DNS queries are processed in-memory and immediately discarded
- **No domain name storage**: Domain names are never persisted to disk
- **No user tracking**: No analytics, telemetry, or user behavior tracking
- **In-memory processing**: All data structures loaded at startup, discarded on shutdown
- **Anonymous caching**: DNS responses cached with hashed keys, no domain storage

## Performance Targets

- **DNS Query Lookup**: <1ms (using Trie + Bloom filter)
- **DNS Resolution**: <5ms (encrypted DNS)
- **Memory Usage**: <150MB total
- **Cache Hit Rate**: >85%

## Development Guidelines

### Go Development
- Uses Go 1.21+ with Gin web framework
- Privacy-first middleware: no request logging, privacy headers
- Structured as microservices with health check endpoints
- Data models emphasize privacy (no user data tracking)

### Swift Development
- macOS 12+ with SwiftUI
- NetworkExtension framework for system DNS interception
- Swift Package Manager for dependencies
- Xcode 15+ required for development

### High-Performance Algorithms & Data Structures
Based on detailed performance analysis in the documentation:
- **Trie (Prefix Tree)**: O(m) domain lookup where m is domain length - excellent for prefix matching
- **Hash Tables**: O(1) average case for exact domain lookups - fast but high memory usage
- **Bloom Filters**: O(1) probabilistic filtering - memory efficient with rare false positives
- **LRU Cache**: O(1) cache access for frequently accessed domains
- **Connection Pooling**: O(1) connection retrieval for efficient DNS connection reuse
- **Circuit Breaker Pattern**: O(1) fault tolerance for network resilience

### Testing
- Run `make test` to execute all tests
- Privacy audit with `make privacy-audit`
- Performance benchmarks: `cd backend && go test -bench=. ./...`
- Unit testing with XCTest/XCUITest for Swift components

## Key Files

- `Makefile`: Complete build and development workflow with all targets
- `backend/cmd/api-server/main.go`: Main API server with privacy-first design
- `backend/internal/models/blocklist.go`: Blocklist data structures and privacy models
- `frontend/Shroudinger/ShroudingerExtension/DNSProxyProvider.swift`: NetworkExtension implementation
- `frontend/Shroudinger/Shroudinger/ShroudingerAppApp.swift`: Main app entry point
- `Blocklist/BlocklistManager.swift`: Blocklist management logic
- `docs/development/CLAUDE.md`: Additional project documentation and architecture details
- `scripts/privacy-audit.sh`: Privacy compliance audit script

## Development Timeline

The project is planned for 18-20 weeks across 8 phases with 94 total development days:

### Phase Breakdown
- **Phase 1-2 (Weeks 1-2)**: Foundation - Project setup, architecture design, core infrastructure
- **Phase 3-4 (Weeks 3-8)**: Core Engine - Network extension implementation, DNS encryption protocols
- **Phase 5-6 (Weeks 9-12)**: Feature Development - Blocklist system, user interface
- **Phase 7-8 (Weeks 13-18)**: Polish and Deployment - Testing, optimization, distribution

### Critical Implementation Requirements
- **Network Extension entitlement** required for DNS proxy functionality
- **App Sandbox** compatibility while maintaining network extension capabilities
- **System Extension approval** process through macOS System Preferences
- **Developer ID signing** for distribution outside Mac App Store
- **Notarization** required for macOS distribution

### Blocklist Management
- **Multi-format support**: Adblock Plus, hosts files, domain lists
- **Automatic updates**: Scheduled fetching from remote sources
- **User customization**: Whitelist management and custom rules
- **Performance monitoring**: Real-time blocklist effectiveness metrics

## Important Notes

- This is a defensive security application focused on DNS privacy and ad blocking
- All services emphasize privacy: no logging, no user data persistence, no tracking
- The system uses high-performance data structures (Trie, Bloom filters) for real-time DNS filtering
- NetworkExtension requires special entitlements and system approval on macOS
- Development follows a comprehensive architectural blueprint with detailed technical specifications
- Focus on native macOS experience with system-level DNS interception capabilities