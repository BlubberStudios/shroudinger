# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS DNS privacy application called "Shroudinger" - a system-level DNS blocklist and encryption app. The project is currently in the planning and architecture phase with comprehensive documentation and technical specifications.

## Key Architecture Components

### Core System Design
- **Network Extension**: Uses NEDNSProxyProvider for system-wide DNS interception
- **Multi-process Architecture**: Separate processes for UI, app logic, and network extension
- **Encrypted DNS Protocols**: Support for DoT (DNS over TLS), DoH (DNS over HTTPS), and DoQ (DNS over QUIC)
- **High-performance Filtering**: Trie data structures for microsecond domain lookups

### Technology Stack
- **Language**: Swift 5.9+ with async/await structured concurrency
- **UI Framework**: SwiftUI with MenuBarExtra for menu bar integration
- **Networking**: NetworkExtension framework with NEDNSProxyProvider
- **Data Structures**: Trie (prefix tree), hash tables, Bloom filters for blocklist storage
- **Testing**: XCTest and XCUITest for unit and UI testing

## Development Commands

Since this is a planning-phase project, there are no build commands yet. When implementation begins, typical macOS development commands will include:

- `xcodebuild`: Build the project
- `xcodebuild test`: Run tests
- `swift package`: Manage Swift packages
- `codesign`: Sign the application for distribution

## Critical Implementation Requirements

### System Integration
- Network Extension entitlement required for DNS proxy functionality
- App Sandbox compatibility while maintaining network extension capabilities
- System Extension approval process through macOS System Preferences
- Developer ID signing for distribution outside Mac App Store

### Performance Targets
- Sub-millisecond blocklist lookups for real-time DNS filtering
- Memory efficient operation to avoid system impact
- Optimized network connections for encrypted DNS servers

### Security Considerations
- Certificate validation for encrypted DNS servers
- DNSSEC support for authenticated DNS responses
- No DNS query logging for privacy protection

## Data Structures and Algorithms

### Blocklist Storage Strategy
- **Trie (Prefix Tree)**: O(m) lookup time where m is domain length
- **Hash Table**: O(1) average case for exact domain lookups
- **Bloom Filter**: O(1) probabilistic filtering to reduce false positives

### Memory Management
- **LRU Cache**: O(1) cache access for frequently accessed domains
- **Object Pooling**: Reduces garbage collection pressure
- **Reference Counting**: Automatic memory management for Swift objects

### Network Performance
- **Connection Pooling**: Efficient reuse of encrypted DNS connections
- **Circuit Breaker Pattern**: Automatic failover during server unavailability
- **Exponential Backoff**: Intelligent retry mechanisms for network resilience

## Development Timeline

The project is planned for 18-20 weeks across 8 phases:
1. Foundation (Weeks 1-2): Project setup and architecture
2. Core Engine (Weeks 3-8): Network extension and DNS encryption
3. Feature Development (Weeks 9-12): Blocklist system and UI
4. Polish and Deployment (Weeks 13-18): Testing and distribution

## Key Files and Documentation

- `Project Blueprint for Claude_ Basic Structure & Im.md`: General project structure guidelines
- `macOS DNS Blocklist App_ Complete Architectural Bl.md`: Comprehensive architectural blueprint
- `What tech stack - frameworks, developer tools, sdk.md`: Technology stack decisions
- `macos_dns_app_tech_stack.csv`: Detailed technology framework listing
- `macos_dns_app_algorithms_datastructures.csv`: Performance algorithms and data structures
- `dns_app_architecture.png`: System architecture diagram
- `dns_filtering_flow.png`: DNS filtering process flow diagram
- `tech_stack_diagram.png`: Technology stack visualization

## Code Style and Conventions

Follow standard Swift and macOS development conventions:
- Use SwiftUI for modern declarative UI
- Implement proper error handling with structured concurrency
- Follow Apple's Human Interface Guidelines for macOS
- Use Swift Package Manager for dependency management
- Implement comprehensive unit tests with XCTest

## Important Notes

This is a defensive security application focused on DNS privacy and ad blocking. The system operates at the network level to provide comprehensive protection while maintaining user privacy through encrypted DNS protocols.