package models

import (
	"time"
)

// BlocklistEntry represents a domain blocking rule
// Privacy-first: Only rule data, no user interaction tracking
type BlocklistEntry struct {
	Domain    string    `json:"domain"`    // Domain to block
	Type      string    `json:"type"`      // exact, wildcard, regex
	Category  string    `json:"category"`  // ads, tracking, malware, etc.
	Source    string    `json:"source"`    // Source blocklist name
	Priority  int       `json:"priority"`  // Higher priority = more important
	CreatedAt time.Time `json:"created_at"`
	// Note: No user who added it, no usage tracking
}

// BlocklistSource represents a blocklist source configuration
type BlocklistSource struct {
	Name        string    `json:"name"`         // "StevenBlack", "AdGuard", etc.
	URL         string    `json:"url"`          // Source URL
	Format      string    `json:"format"`       // hosts, adblock, domains
	Category    string    `json:"category"`     // ads, tracking, malware
	Enabled     bool      `json:"enabled"`      // Is this source active
	Priority    int       `json:"priority"`     // Source priority
	UpdateFreq  string    `json:"update_freq"`  // "daily", "weekly", etc.
	LastUpdate  time.Time `json:"last_update"`  // When last updated
	EntryCount  int       `json:"entry_count"`  // Number of entries
	// Note: No user preferences, no usage tracking
}

// BlocklistStats represents blocklist statistics without user data
type BlocklistStats struct {
	TotalEntries    int64     `json:"total_entries"`
	ActiveSources   int       `json:"active_sources"`
	LastUpdate      time.Time `json:"last_update"`
	UpdateFrequency string    `json:"update_frequency"`
	Categories      map[string]int `json:"categories"` // category -> count
	// Note: No blocked query history, no user statistics
}

// BlocklistConfig represents blocklist configuration
type BlocklistConfig struct {
	Sources          []BlocklistSource `json:"sources"`
	UpdateInterval   time.Duration     `json:"update_interval"`
	AutoUpdate       bool              `json:"auto_update"`
	EnableWildcards  bool              `json:"enable_wildcards"`
	EnableRegex      bool              `json:"enable_regex"`
	MaxEntries       int               `json:"max_entries"`
	CompressionLevel int               `json:"compression_level"`
	// Note: No user-specific settings
}

// BlocklistUpdateResult represents the result of a blocklist update
type BlocklistUpdateResult struct {
	Source         string    `json:"source"`
	Status         string    `json:"status"`         // success, error, partial
	EntriesAdded   int       `json:"entries_added"`
	EntriesRemoved int       `json:"entries_removed"`
	EntriesUpdated int       `json:"entries_updated"`
	Duration       time.Duration `json:"duration"`
	ErrorMessage   string    `json:"error_message,omitempty"`
	UpdatedAt      time.Time `json:"updated_at"`
	// Note: No user who triggered the update
}

// BlocklistMergeResult represents the result of merging multiple blocklists
type BlocklistMergeResult struct {
	SourcesProcessed int           `json:"sources_processed"`
	TotalEntries     int           `json:"total_entries"`
	DuplicatesRemoved int          `json:"duplicates_removed"`
	MergeTime        time.Duration `json:"merge_time"`
	CompressionRatio float64       `json:"compression_ratio"`
	// Note: No user data involved
}

// BlocklistQuery represents a query against the blocklist
// Used internally, never persisted to maintain privacy
type BlocklistQuery struct {
	QueryID     string
	QueryType   string // exact, wildcard, regex
	IsBlocked   bool
	BlockReason string // Category that blocked it
	MatchedRule string // Rule that matched (for debugging)
	QueryTime   time.Duration
	// Note: No domain name stored to maintain privacy
}

// BlocklistCache represents in-memory blocklist cache
type BlocklistCache struct {
	// Privacy-first: Only domain hashes, no actual domains
	entries   map[string]*BlocklistEntry // Hash -> Entry
	trie      interface{}                // Trie data structure
	bloom     interface{}                // Bloom filter for fast negatives
	stats     struct {
		Hits      int64
		Misses    int64
		Size      int64
		LoadTime  time.Duration
	}
	lastUpdate time.Time
}

// BlocklistManager represents the blocklist management system
type BlocklistManager struct {
	Sources []BlocklistSource `json:"sources"`
	Cache   *BlocklistCache   `json:"-"` // Not serialized
	Config  BlocklistConfig   `json:"config"`
	Stats   BlocklistStats    `json:"stats"`
	// Note: No user data, no usage tracking
}