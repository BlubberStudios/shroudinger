import Foundation

struct Constants {
    
    // App Info
    static let appName = "Shroudinger DNS Privacy"
    static let appVersion = "1.0"
    static let appBundleId = "com.shroudinger.app"
    static let extensionBundleId = "com.shroudinger.app.extension"
    
    // DNS Servers
    struct DNSServers {
        static let cloudflare = ["1.1.1.1", "1.0.0.1"]
        static let cloudflareDoH = "https://cloudflare-dns.com/dns-query"
        static let cloudflareDoT = "one.one.one.one"
        
        static let quad9 = ["9.9.9.9", "149.112.112.112"]
        static let quad9DoH = "https://dns.quad9.net/dns-query"
        static let quad9DoT = "dns.quad9.net"
        
        static let google = ["8.8.8.8", "8.8.4.4"]
        static let googleDoH = "https://dns.google/dns-query"
        static let googleDoT = "dns.google"
    }
    
    // Networking
    struct Network {
        static let dnsPort = 53
        static let dohPort = 443
        static let dotPort = 853
        static let doqPort = 853
        static let defaultTimeout: TimeInterval = 5.0
    }
    
    // Blocklist Sources
    struct BlocklistSources {
        static let stevenBlackHosts = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        static let adguardDNS = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
        static let easyList = "https://easylist.to/easylist/easylist.txt"
        static let easyPrivacy = "https://easylist.to/easylist/easyprivacy.txt"
    }
    
    // App Settings Keys
    struct SettingsKeys {
        static let encryptedDNSEnabled = "encryptedDNSEnabled"
        static let blockAdsEnabled = "blockAdsEnabled"
        static let blockTrackersEnabled = "blockTrackersEnabled"
        static let blockMalwareEnabled = "blockMalwareEnabled"
        static let selectedDNSProvider = "selectedDNSProvider"
        static let customDNSServers = "customDNSServers"
        static let enableLogging = "enableLogging"
        static let autoUpdateBlocklists = "autoUpdateBlocklists"
        static let updateInterval = "updateInterval"
        static let settingsInitialized = "settingsInitialized"
    }
    
    // Statistics
    struct Statistics {
        static let totalQueries = "totalQueries"
        static let blockedQueries = "blockedQueries"
        static let allowedQueries = "allowedQueries"
        static let cacheHits = "cacheHits"
        static let cacheMisses = "cacheMisses"
    }
    
    // File Paths
    struct FilePaths {
        static let blocklistsDirectory = "Blocklists"
        static let cacheDirectory = "Cache"
        static let logsDirectory = "Logs"
        static let configFile = "config.plist"
    }
    
    // UI Constants
    struct UI {
        static let minWindowWidth: CGFloat = 600
        static let minWindowHeight: CGFloat = 400
        static let preferredWindowWidth: CGFloat = 800
        static let preferredWindowHeight: CGFloat = 600
    }
    
    // System Extension
    struct SystemExtension {
        static let identifier = "com.shroudinger.app.extension"
        static let displayName = "Shroudinger DNS Extension"
        static let description = "Provides system-wide DNS filtering and privacy protection"
    }
}
