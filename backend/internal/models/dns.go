package models

import (
	"time"
)

// DNSQuery represents a DNS query without storing the actual domain
// Privacy-first: Only metadata, no user data
type DNSQuery struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"`        // A, AAAA, CNAME, etc.
	Timestamp   time.Time `json:"timestamp"`
	// Note: No Domain field to maintain privacy
}

// DNSResponse represents a DNS response without logging user data
type DNSResponse struct {
	ID           string        `json:"id"`
	Status       string        `json:"status"`       // resolved, blocked, error
	Blocked      bool          `json:"blocked"`
	ResponseTime time.Duration `json:"response_time"`
	Resolver     string        `json:"resolver"`     // encrypted, cached, etc.
	Timestamp    time.Time     `json:"timestamp"`
	// Note: No domain name or IP addresses to maintain privacy
}

// DNSServer represents an encrypted DNS server configuration
type DNSServer struct {
	Name     string `json:"name"`     // Cloudflare, Quad9, etc.
	Address  string `json:"address"`  // 1.1.1.1, 9.9.9.9, etc.
	Port     int    `json:"port"`     // 853 for DoT, 443 for DoH
	Protocol string `json:"protocol"` // DoT, DoH, DoQ
	Status   string `json:"status"`   // active, inactive, error
}

// DNSStats represents runtime statistics without user data
type DNSStats struct {
	QueriesProcessed int64         `json:"queries_processed"`
	DomainsBlocked   int64         `json:"domains_blocked"`
	CacheHitRate     float64       `json:"cache_hit_rate"`
	AverageLatency   time.Duration `json:"average_latency"`
	ActiveServers    int           `json:"active_servers"`
	Uptime           time.Duration `json:"uptime"`
	// Note: No domain lists, no user query history
}

// DNSQueryResult represents the result of a DNS query processing
// Used internally, never persisted
type DNSQueryResult struct {
	QueryID      string
	IsBlocked    bool
	BlockReason  string // "blocklist", "malware", etc.
	ResponseTime time.Duration
	ResolverUsed string
	// Note: No domain name stored
}

// DNSCache represents anonymous DNS response caching
type DNSCache struct {
	// Uses hashed keys instead of domain names for privacy
	responses map[string]*DNSResponse
	ttl       map[string]time.Time
	stats     struct {
		Hits   int64
		Misses int64
		Size   int64
	}
}

// DNSServerPool manages encrypted DNS server connections
type DNSServerPool struct {
	Servers     []DNSServer `json:"servers"`
	ActiveCount int         `json:"active_count"`
	DefaultServer string    `json:"default_server"`
	LoadBalancing string    `json:"load_balancing"` // round_robin, random, etc.
}

// DNSConfig represents DNS service configuration
type DNSConfig struct {
	ServerPool      DNSServerPool     `json:"server_pool"`
	CacheEnabled    bool              `json:"cache_enabled"`
	CacheTTL        time.Duration     `json:"cache_ttl"`
	Timeout         time.Duration     `json:"timeout"`
	RetryAttempts   int               `json:"retry_attempts"`
	PrivacyMode     bool              `json:"privacy_mode"`
	NoQueryLogging  bool              `json:"no_query_logging"`
	NoDomainLogging bool              `json:"no_domain_logging"`
}