# Project: macOS DNS Blocklist App

## Project Goal

The project is to create a macOS application that provides DNS-level ad and tracker blocking. It will use a local DNS proxy to filter DNS requests against a blocklist.

## Core Components

*   **Main Application (GUI):** A SwiftUI application for user interaction, settings, and status updates.
*   **DNS Proxy/Filter:** A local DNS proxy (likely a Network Extension) that intercepts and filters DNS traffic.
*   **Blocklist Manager:** A component to download, update, and manage the blocklists.
*   **Settings/Configuration:** A mechanism to store and manage user settings.

## Tech Stack

*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Networking:** `NetworkExtension` framework for DNS proxying.
*   **Data Storage:** `CoreData` or `UserDefaults` for settings and blocklists.

## Development Tools

*   **IDE:** Xcode
*   **Build System:** Xcode Build System
*   **Package Manager:** Swift Package Manager

## Key Features

*   Block ads and trackers at the DNS level.
*   System-wide filtering.
*   User-configurable blocklists.
*   Real-time connection logging.
*   Whitelisting/blacklisting of domains.
*   Statistics and reporting.
