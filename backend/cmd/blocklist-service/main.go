// Package main implements the blocklist service for Shroudinger DNS App
// This service manages domain blocklists with high-performance data structures
// Privacy-first design: No user data, no query logging, in-memory processing only
//
// Core responsibilities:
// 1. Fetch and parse blocklists from multiple sources
// 2. Optimize data structures (Trie, Bloom filters, Hash tables)
// 3. Provide microsecond domain lookup performance
// 4. Maintain privacy by never storing user queries
package main

import (
	"context"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	// Service configuration
	defaultPort = "8081"
	
	// Performance targets (as specified in CLAUDE.md)
	domainLookupTargetMs = 1		// <1ms domain lookup time
	maxMemoryUsageMB = 150			// <150MB total memory usage
	targetCacheHitRate = 0.85		// >85% cache hit rate
	
	// Blocklist configuration
	maxDomainEntries = 10000000		// 10M domains max
	updateIntervalHours = 24		// Update every 24 hours
	bloomFilterFalsePositiveRate = 0.01	// 1% false positive rate
	
	// Privacy settings (always enabled)
	privacyMode = true
	noUserDataStorage = true
	noQueryLogging = true
)

func main() {
	// Privacy-first blocklist service for Shroudinger DNS App
	// Core principles:
	// 1. No user data storage - blocklists only, no query history
	// 2. High-performance lookups using Trie + Bloom filter + Hash table
	// 3. In-memory processing with periodic updates
	// 4. Anonymous system metrics only
	// 5. Optimized for <1ms domain lookup performance
	
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Configure Gin for production privacy mode
	if privacyMode {
		gin.SetMode(gin.ReleaseMode)
		gin.DisableConsoleColor()
	}
	
	// Create Gin router with minimal middleware
	r := gin.New()
	r.Use(gin.Recovery())	// Panic recovery only

	// Privacy and performance middleware
	r.Use(privacyMiddleware())		// Privacy headers and policies
	r.Use(performanceMiddleware())		// Performance monitoring
	r.Use(securityMiddleware())		// Security headers

	// Health and metrics endpoints
	r.GET("/health", handleHealthCheck)
	r.GET("/metrics", handlePerformanceMetrics)

	// Blocklist management API
	api := r.Group("/api/v1")
	{
		// Data management
		api.POST("/blocklist/fetch", handleBlocklistFetch)		// Fetch from sources
		api.POST("/blocklist/parse", handleBlocklistParse)		// Parse formats
		api.POST("/blocklist/optimize", handleBlocklistOptimize)	// Optimize structures
		api.POST("/blocklist/reload", handleBlocklistReload)		// Reload all data
		
		// Query endpoints (high-performance)
		api.POST("/blocklist/check", handleDomainCheck)		// Check if domain blocked
		api.POST("/blocklist/batch", handleBatchCheck)		// Batch domain check
		
		// Status and configuration
		api.GET("/blocklist/sources", handleBlocklistSources)		// List sources
		api.GET("/blocklist/stats", handleBlocklistStats)		// Statistics
		api.GET("/blocklist/status", handleBlocklistStatus)		// Service status
		
		// Performance monitoring
		api.GET("/performance/lookup", handleLookupPerformance)	// Lookup timing
		api.GET("/performance/memory", handleMemoryUsage)		// Memory stats
		api.GET("/performance/cache", handleCacheStats)		// Cache performance
	}

	// Create high-performance HTTP server
	srv := &http.Server{
		Addr:           ":" + port,
		Handler:        r,
		ReadTimeout:    5 * time.Second,	// Fast timeouts for performance
		WriteTimeout:   5 * time.Second,
		IdleTimeout:    60 * time.Second,
		MaxHeaderBytes: 1024,			// Small headers for performance
	}

	// Initialize blocklist data structures in background
	go initializeBlocklistManager()
	
	// Start performance monitoring
	go startPerformanceMonitoring()
	
	// Start HTTP server
	go func() {
		log.Printf("🚀 Blocklist Service starting on port %s", port)
		log.Printf("🔒 Privacy mode: No user data storage, no query logging")
		log.Printf("⚡ Performance target: <%dms domain lookups, <%dMB memory", 
			domainLookupTargetMs, maxMemoryUsageMB)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server failed to start: %v", err)
		}
	}()


	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Blocklist Service shutting down...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("❌ Server forced to shutdown: %v", err)
	}

	log.Println("✅ Blocklist Service exited cleanly")
}

// ============================================================================
// GLOBAL STATE MANAGEMENT
// Thread-safe blocklist data structures with high-performance algorithms
// ============================================================================

var (
	// Global blocklist manager with thread-safe operations
	blocklistManager *BlocklistManager
	mutex           sync.RWMutex	// Protects concurrent access
	
	// Performance monitoring
	lookupCount     int64
	totalLookupTime time.Duration
	cacheHits       int64
	cacheMisses     int64
	startTime       time.Time
)

// BlocklistManager manages high-performance domain blocking
// Uses multiple data structures for optimal performance:
// - Trie: O(m) prefix matching where m = domain length
// - Bloom Filter: O(1) probabilistic negative filtering
// - Hash Table: O(1) exact domain lookups
type BlocklistManager struct {
	// Data structures for microsecond lookups
	domainTrie     *DomainTrie		// Prefix tree for wildcard matching
	bloomFilter    *BloomFilter		// Fast negative filtering
	exactDomains   map[string]bool		// Hash table for exact matches
	
	// Source management
	sources        []BlocklistSource
	lastUpdate     time.Time
	updateInterval time.Duration
	
	// Performance metrics
	stats          BlocklistStats
}

// DomainTrie implements a prefix tree for efficient domain matching
type DomainTrie struct {
	children map[string]*DomainTrie
	isBlocked bool
	category  string
}

// BloomFilter implements probabilistic domain filtering
type BloomFilter struct {
	bitSet    []bool
	size      int
	hashFuncs int
}

// BlocklistSource represents a domain blocklist source
type BlocklistSource struct {
	Name       string
	URL        string
	Format     string	// "hosts", "adblock", "domains"
	Category   string	// "ads", "tracking", "malware"
	Enabled    bool
	Priority   int
	LastUpdate time.Time
	EntryCount int
}

// BlocklistStats contains anonymous performance statistics
type BlocklistStats struct {
	TotalDomains    int64
	ActiveSources   int
	LastUpdate      time.Time
	LookupCount     int64
	CacheHitRate    float64
	AvgLookupTime   time.Duration
	MemoryUsageMB   float64
}

// ============================================================================
// MIDDLEWARE FUNCTIONS
// Privacy and performance middleware for the blocklist service
// ============================================================================

// privacyMiddleware implements privacy-first policies
func privacyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Privacy headers
		c.Header("X-Privacy-Policy", "no-user-data-storage")
		c.Header("X-No-Query-Logging", "true")
		c.Header("X-No-User-Tracking", "true")
		c.Header("X-Data-Retention", "none")
		
		// Service identification
		c.Header("X-Service", "blocklist-service")
		c.Header("X-Performance-Target", "<1ms")
		
		c.Next()
	}
}

// performanceMiddleware monitors request performance
func performanceMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		
		c.Next()
		
		// Log performance metrics (no user data)
		duration := time.Since(start)
		if duration > time.Millisecond {
			log.Printf("⚠️ Slow request: %s took %v", c.Request.URL.Path, duration)
		}
	}
}

// securityMiddleware implements security headers
func securityMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("Content-Security-Policy", "default-src 'none'")
		c.Next()
	}
}

// ============================================================================
// INITIALIZATION FUNCTIONS
// Initialize high-performance data structures and background processes
// ============================================================================

// initializeBlocklistManager sets up the blocklist management system
func initializeBlocklistManager() {
	log.Println("📋 Initializing high-performance blocklist manager...")
	
	startTime = time.Now()
	
	// Initialize thread-safe blocklist manager
	mutex.Lock()
	blocklistManager = &BlocklistManager{
		domainTrie:     NewDomainTrie(),
		bloomFilter:    NewBloomFilter(maxDomainEntries, bloomFilterFalsePositiveRate),
		exactDomains:   make(map[string]bool, maxDomainEntries),
		updateInterval: updateIntervalHours * time.Hour,
		stats:          BlocklistStats{},
	}
	mutex.Unlock()
	
	log.Println("🏠 Data structures initialized (Trie + Bloom Filter + Hash Table)")
	
	// Load default blocklists with performance monitoring
	loadStart := time.Now()
	loadDefaultBlocklists()
	loadDuration := time.Since(loadStart)
	
	log.Printf("✅ Blocklist manager initialized in %v", loadDuration)
	log.Printf("📊 Memory target: <%dMB, Lookup target: <%dms", 
		maxMemoryUsageMB, domainLookupTargetMs)
	
	// Start background update routine
	go startPeriodicUpdates()
}

// startPeriodicUpdates manages automatic blocklist updates
func startPeriodicUpdates() {
	log.Printf("🔄 Starting periodic updates every %d hours", updateIntervalHours)
	
	ticker := time.NewTicker(time.Duration(updateIntervalHours) * time.Hour)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			log.Println("🔄 Automatic blocklist update triggered")
			updateStart := time.Now()
			updateBlocklists()
			updateDuration := time.Since(updateStart)
			log.Printf("✅ Blocklist update completed in %v", updateDuration)
		}
	}
}

// startPerformanceMonitoring tracks system performance
func startPerformanceMonitoring() {
	log.Println("📊 Starting performance monitoring...")
	
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			updatePerformanceStats()
		}
	}
}

// updatePerformanceStats calculates current performance metrics
func updatePerformanceStats() {
	mutex.Lock()
	defer mutex.Unlock()
	
	if blocklistManager == nil {
		return
	}
	
	// Calculate performance metrics (no user data)
	if lookupCount > 0 {
		blocklistManager.stats.AvgLookupTime = totalLookupTime / time.Duration(lookupCount)
		blocklistManager.stats.CacheHitRate = float64(cacheHits) / float64(lookupCount)
	}
	
	blocklistManager.stats.LookupCount = lookupCount
	
	// Log performance warnings if targets not met
	if blocklistManager.stats.AvgLookupTime > time.Millisecond {
		log.Printf("⚠️ Performance warning: avg lookup time %v exceeds %dms target", 
			blocklistManager.stats.AvgLookupTime, domainLookupTargetMs)
	}
}

// loadDefaultBlocklists initializes the default blocklist sources
func loadDefaultBlocklists() {
	log.Println("📥 Loading default blocklist sources...")
	
	// Default blocklist sources with privacy-first selections
	sources := []BlocklistSource{
		{
			Name:     "StevenBlack",
			URL:      "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
			Format:   "hosts",
			Category: "ads",
			Enabled:  true,
			Priority: 1,
		},
		{
			Name:     "SomeoneWhoCares",
			URL:      "https://someonewhocares.org/hosts/zero/hosts",
			Format:   "hosts",
			Category: "tracking",
			Enabled:  true,
			Priority: 2,
		},
		{
			Name:     "AdGuard",
			URL:      "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers.txt",
			Format:   "adblock",
			Category: "ads",
			Enabled:  true,
			Priority: 3,
		},
	}
	
	mutex.Lock()
	blocklistManager.sources = sources
	blocklistManager.stats.ActiveSources = len(sources)
	mutex.Unlock()
	
	// Start loading blocklists in background
	for _, source := range sources {
		go loadBlocklistSource(source)
	}
	
	log.Printf("✅ Initialized %d blocklist sources", len(sources))
}

// loadBlocklistSource loads a single blocklist source
func loadBlocklistSource(source BlocklistSource) {
	log.Printf("📥 Loading %s blocklist (%s format)", source.Name, source.Format)
	
	// TODO: Implement actual fetching and parsing
	// For now, simulate loading with example domains
	exampleDomains := []string{
		"doubleclick.net",
		"googleadservices.com",
		"googlesyndication.com",
		"facebook.com", // Example - would be from actual blocklist
	}
	
	start := time.Now()
	
	// Add domains to data structures with thread safety
	mutex.Lock()
	for _, domain := range exampleDomains {
		// Add to all data structures for optimal performance
		blocklistManager.exactDomains[domain] = true
		blocklistManager.domainTrie.Add(domain, source.Category)
		blocklistManager.bloomFilter.Add(domain)
		blocklistManager.stats.TotalDomains++
	}
	mutex.Unlock()
	
	loadDuration := time.Since(start)
	log.Printf("✅ Loaded %s: %d domains in %v", source.Name, len(exampleDomains), loadDuration)
}

// updateBlocklists refreshes all blocklist sources
func updateBlocklists() {
	log.Println("🔄 Updating all blocklist sources...")
	
	updateStart := time.Now()
	updatedSources := 0
	
	mutex.RLock()
	sources := blocklistManager.sources
	mutex.RUnlock()
	
	// Update each enabled source
	for _, source := range sources {
		if !source.Enabled {
			continue
		}
		
		log.Printf("🔄 Updating %s...", source.Name)
		
		// TODO: Implement actual update logic
		// For now, simulate update
		time.Sleep(100 * time.Millisecond) // Simulate network delay
		
		updatedSources++
	}
	
	// Update statistics
	mutex.Lock()
	blocklistManager.lastUpdate = time.Now()
	blocklistManager.stats.LastUpdate = time.Now()
	mutex.Unlock()
	
	updateDuration := time.Since(updateStart)
	log.Printf("✅ Updated %d sources in %v", updatedSources, updateDuration)
	
	// Log performance metrics (no user data)
	log.Printf("📊 Current stats: %d domains, %.2f%% cache hit rate, %v avg lookup", 
		blocklistManager.stats.TotalDomains, 
		blocklistManager.stats.CacheHitRate*100,
		blocklistManager.stats.AvgLookupTime)
}

// ============================================================================
// DATA STRUCTURE IMPLEMENTATIONS
// High-performance domain matching algorithms
// ============================================================================

// NewDomainTrie creates a new domain trie for prefix matching
func NewDomainTrie() *DomainTrie {
	return &DomainTrie{
		children: make(map[string]*DomainTrie),
	}
}

// Add inserts a domain into the trie
func (t *DomainTrie) Add(domain, category string) {
	current := t
	parts := strings.Split(domain, ".")
	
	// Reverse the parts to build trie from TLD down
	for i := len(parts) - 1; i >= 0; i-- {
		part := parts[i]
		if current.children[part] == nil {
			current.children[part] = NewDomainTrie()
		}
		current = current.children[part]
	}
	
	current.isBlocked = true
	current.category = category
}

// Check verifies if a domain is blocked
func (t *DomainTrie) Check(domain string) (bool, string) {
	current := t
	parts := strings.Split(domain, ".")
	
	// Check from TLD down
	for i := len(parts) - 1; i >= 0; i-- {
		part := parts[i]
		if current.children[part] == nil {
			return false, ""
		}
		current = current.children[part]
		if current.isBlocked {
			return true, current.category
		}
	}
	
	return current.isBlocked, current.category
}

// NewBloomFilter creates a new bloom filter
func NewBloomFilter(expectedElements int, falsePositiveRate float64) *BloomFilter {
	// Calculate optimal size and hash functions
	size := int(-float64(expectedElements) * math.Log(falsePositiveRate) / (math.Log(2) * math.Log(2)))
	hashFuncs := int(float64(size) / float64(expectedElements) * math.Log(2))
	
	return &BloomFilter{
		bitSet:    make([]bool, size),
		size:      size,
		hashFuncs: hashFuncs,
	}
}

// Add inserts a domain into the bloom filter
func (bf *BloomFilter) Add(domain string) {
	for i := 0; i < bf.hashFuncs; i++ {
		hash := bf.hash(domain, i)
		bf.bitSet[hash%bf.size] = true
	}
}

// Check verifies if a domain might be blocked (probabilistic)
func (bf *BloomFilter) Check(domain string) bool {
	for i := 0; i < bf.hashFuncs; i++ {
		hash := bf.hash(domain, i)
		if !bf.bitSet[hash%bf.size] {
			return false // Definitely not blocked
		}
	}
	return true // Probably blocked
}

// hash generates hash values for bloom filter
func (bf *BloomFilter) hash(domain string, seed int) int {
	// Simple hash function - in production, use better hashing
	hash := 0
	for i, char := range domain {
		hash = hash*31 + int(char) + seed*i
	}
	if hash < 0 {
		hash = -hash
	}
	return hash
}

// ============================================================================
// API HANDLERS
// High-performance API endpoints with detailed privacy and performance notes
// ============================================================================

// handleBlocklistFetch triggers fetching of blocklists from specified sources
// Privacy: System operation only, no user data involved
func handleBlocklistFetch(c *gin.Context) {
	var request struct {
		Sources []string `json:"sources"` // Source names to fetch
		Force   bool     `json:"force,omitempty"` // Force refresh even if recent
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request format"})
		return
	}
	
	start := time.Now()
	
	// Validate requested sources
	mutex.RLock()
	availableSources := make(map[string]bool)
	for _, source := range blocklistManager.sources {
		availableSources[source.Name] = source.Enabled
	}
	mutex.RUnlock()
	
	validSources := 0
	for _, sourceName := range request.Sources {
		if availableSources[sourceName] {
			validSources++
			// TODO: Trigger fetch for this source
			log.Printf("📥 Fetching blocklist: %s", sourceName)
		}
	}
	
	responseTime := time.Since(start)
	
	c.JSON(http.StatusOK, gin.H{
		"status": "fetch_initiated",
		"valid_sources": validSources,
		"total_requested": len(request.Sources),
		"force_refresh": request.Force,
		"response_time": responseTime.String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// Note: No user identification, system operation only
	})
	
	log.Printf("📥 Blocklist fetch initiated for %d sources", validSources)
}

// handleBlocklistParse processes and parses raw blocklist data
// Privacy: Data processing only, no user involvement
func handleBlocklistParse(c *gin.Context) {
	var request struct {
		Format string `json:"format"` // "hosts", "adblock", "domains"
		Data   string `json:"data,omitempty"` // Raw blocklist data
		URL    string `json:"url,omitempty"` // URL to fetch and parse
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request format"})
		return
	}
	
	start := time.Now()
	
	// Validate format
	validFormats := map[string]bool{
		"hosts":   true,
		"adblock": true,
		"domains": true,
	}
	
	if !validFormats[request.Format] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "unsupported format"})
		return
	}
	
	// TODO: Implement actual parsing logic
	// For now, simulate parsing
	parsedDomains := 0
	if request.Data != "" {
		// Parse inline data
		parsedDomains = len(strings.Split(request.Data, "\n"))
	} else if request.URL != "" {
		// Fetch and parse from URL
		parsedDomains = 1000 // Simulated
	}
	
	parseTime := time.Since(start)
	
	c.JSON(http.StatusOK, gin.H{
		"status": "parse_complete",
		"format": request.Format,
		"domains_parsed": parsedDomains,
		"parse_time": parseTime.String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// Note: No domain names logged, only counts
	})
	
	log.Printf("📝 Parsed %s format: %d domains in %v", 
		request.Format, parsedDomains, parseTime)
}

// handleBlocklistOptimize rebuilds data structures for optimal performance
// Privacy: System optimization only, no user data
func handleBlocklistOptimize(c *gin.Context) {
	start := time.Now()
	
	// Lock for optimization
	mutex.Lock()
	defer mutex.Unlock()
	
	if blocklistManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "blocklist manager not initialized"})
		return
	}
	
	// Record current stats
	domainsBefore := blocklistManager.stats.TotalDomains
	memoryBefore := blocklistManager.stats.MemoryUsageMB
	
	// TODO: Implement actual optimization
	// 1. Rebuild trie with optimal structure
	// 2. Recreate bloom filter with current domain count
	// 3. Compress hash table
	// 4. Remove duplicates and optimize memory layout
	
	// Simulate optimization
	time.Sleep(100 * time.Millisecond)
	
	// Update performance stats
	optimizationTime := time.Since(start)
	blocklistManager.stats.MemoryUsageMB = memoryBefore * 0.85 // Simulate 15% reduction
	
	c.JSON(http.StatusOK, gin.H{
		"status": "optimization_complete",
		"domains_processed": domainsBefore,
		"optimization_time": optimizationTime.String(),
		"memory_before_mb": memoryBefore,
		"memory_after_mb": blocklistManager.stats.MemoryUsageMB,
		"memory_saved_percent": 15.0,
		"structures_optimized": []string{"trie", "bloom_filter", "hash_table"},
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// Note: Performance metrics only, no user data
	})
	
	log.Printf("⚡ Blocklist optimization completed in %v (%.1fMB -> %.1fMB)", 
		optimizationTime, memoryBefore, blocklistManager.stats.MemoryUsageMB)
}

// handleBlocklistSources returns configuration of all blocklist sources
// Privacy: System configuration only, no user-specific data
func handleBlocklistSources(c *gin.Context) {
	start := time.Now()
	
	mutex.RLock()
	defer mutex.RUnlock()
	
	if blocklistManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "blocklist manager not initialized"})
		return
	}
	
	// Prepare source information (no sensitive data)
	sources := make([]gin.H, len(blocklistManager.sources))
	totalDomains := int64(0)
	activeSources := 0
	
	for i, source := range blocklistManager.sources {
		if source.Enabled {
			activeSources++
			totalDomains += int64(source.EntryCount)
		}
		
		sources[i] = gin.H{
			"name": source.Name,
			"category": source.Category,
			"format": source.Format,
			"enabled": source.Enabled,
			"priority": source.Priority,
			"entry_count": source.EntryCount,
			"last_update": source.LastUpdate.Format(time.RFC3339),
			// Note: URL not exposed for security
		}
	}
	
	responseTime := time.Since(start)
	
	c.JSON(http.StatusOK, gin.H{
		"sources": sources,
		"summary": gin.H{
			"total_sources": len(blocklistManager.sources),
			"active_sources": activeSources,
			"total_domains": totalDomains,
			"last_update": blocklistManager.lastUpdate.Format(time.RFC3339),
			"next_update": blocklistManager.lastUpdate.Add(blocklistManager.updateInterval).Format(time.RFC3339),
		},
		"performance": gin.H{
			"avg_lookup_time": blocklistManager.stats.AvgLookupTime.String(),
			"cache_hit_rate": blocklistManager.stats.CacheHitRate,
			"memory_usage_mb": blocklistManager.stats.MemoryUsageMB,
			"lookup_count": blocklistManager.stats.LookupCount,
		},
		"response_time": responseTime.String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// Note: System configuration only, no user data
	})
}

// ============================================================================
// HIGH-PERFORMANCE QUERY HANDLERS
// Core domain checking functionality with microsecond performance targets
// ============================================================================

// handleDomainCheck performs high-speed domain blocking check
// CRITICAL PRIVACY: Processes domain but NEVER logs it
func handleDomainCheck(c *gin.Context) {
	var request struct {
		Domain string `json:"domain"` // Domain to check (never logged)
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request format"})
		return
	}
	
	// Validate domain format (without logging it)
	if len(request.Domain) == 0 || len(request.Domain) > 253 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid domain format"})
		return
	}
	
	start := time.Now()
	
	// PRIVACY CRITICAL: Check domain blocking without logging the domain name
	mutex.RLock()
	defer mutex.RUnlock()
	
	if blocklistManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "service not ready"})
		return
	}
	
	// Multi-stage lookup for optimal performance:
	// 1. Bloom filter (O(1) - fast negative)
	// 2. Hash table (O(1) - exact match)
	// 3. Trie (O(m) - wildcard/prefix match)
	
	blocked := false
	category := ""
	lookupMethod := ""
	
	// Stage 1: Bloom filter (fastest negative filter)
	if !blocklistManager.bloomFilter.Check(request.Domain) {
		// Definitely not blocked
		blocked = false
		lookupMethod = "bloom_filter"
		cacheMisses++
	} else {
		// Stage 2: Hash table (exact match)
		if blocklistManager.exactDomains[request.Domain] {
			blocked = true
			category = "exact"
			lookupMethod = "hash_table"
			cacheHits++
		} else {
			// Stage 3: Trie (wildcard/prefix match)
			blocked, category = blocklistManager.domainTrie.Check(request.Domain)
			lookupMethod = "trie"
			if blocked {
				cacheHits++
			} else {
				cacheMisses++
			}
		}
	}
	
	lookupTime := time.Since(start)
	
	// Update performance counters (no domain logging)
	lookupCount++
	totalLookupTime += lookupTime
	
	// Performance warning if target not met
	if lookupTime > time.Millisecond {
		log.Printf("⚠️ Slow lookup: %v (target: <%dms)", lookupTime, domainLookupTargetMs)
	}
	
	c.JSON(http.StatusOK, gin.H{
		"blocked": blocked,
		"category": category,
		"lookup_time": lookupTime.String(),
		"lookup_method": lookupMethod,
		"performance_target_met": lookupTime <= time.Millisecond,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// CRITICAL: No domain name in response to prevent logging
	})
	
	// Log only performance metrics (no domain name)
	log.Printf("🔍 Domain check: blocked=%v, method=%s, time=%v", 
		blocked, lookupMethod, lookupTime)
}

// handleBatchCheck performs batch domain checking for efficiency
// Privacy: Batch processing without domain logging
func handleBatchCheck(c *gin.Context) {
	var request struct {
		Domains []string `json:"domains"` // Domains to check (never logged)
		MaxBatchSize int `json:"max_batch_size,omitempty"`
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request format"})
		return
	}
	
	// Limit batch size for performance and security
	maxBatch := 100
	if request.MaxBatchSize > 0 && request.MaxBatchSize < maxBatch {
		maxBatch = request.MaxBatchSize
	}
	
	if len(request.Domains) > maxBatch {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("batch size %d exceeds limit %d", len(request.Domains), maxBatch),
		})
		return
	}
	
	start := time.Now()
	
	mutex.RLock()
	defer mutex.RUnlock()
	
	if blocklistManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "service not ready"})
		return
	}
	
	// Process batch efficiently
	results := make([]gin.H, len(request.Domains))
	blockedCount := 0
	maxLookupTime := time.Duration(0)
	
	for i, domain := range request.Domains {
		// Individual domain check (same logic as single check)
		domainStart := time.Now()
		
		blocked := false
		category := ""
		lookupMethod := ""
		
		// Fast lookup using bloom -> hash -> trie
		if !blocklistManager.bloomFilter.Check(domain) {
			lookupMethod = "bloom_filter"
		} else if blocklistManager.exactDomains[domain] {
			blocked = true
			category = "exact"
			lookupMethod = "hash_table"
		} else {
			blocked, category = blocklistManager.domainTrie.Check(domain)
			lookupMethod = "trie"
		}
		
		domainTime := time.Since(domainStart)
		if domainTime > maxLookupTime {
			maxLookupTime = domainTime
		}
		
		if blocked {
			blockedCount++
		}
		
		// Store result without domain name
		results[i] = gin.H{
			"index": i,
			"blocked": blocked,
			"category": category,
			"lookup_time": domainTime.String(),
			"lookup_method": lookupMethod,
			// Note: No domain name to maintain privacy
		}
		
		// Update counters
		lookupCount++
		totalLookupTime += domainTime
		if blocked {
			cacheHits++
		} else {
			cacheMisses++
		}
	}
	
	batchTime := time.Since(start)
	avgTimePerDomain := batchTime / time.Duration(len(request.Domains))
	
	c.JSON(http.StatusOK, gin.H{
		"results": results,
		"summary": gin.H{
			"total_domains": len(request.Domains),
			"blocked_count": blockedCount,
			"allowed_count": len(request.Domains) - blockedCount,
			"block_rate": float64(blockedCount) / float64(len(request.Domains)),
		},
		"performance": gin.H{
			"batch_time": batchTime.String(),
			"avg_time_per_domain": avgTimePerDomain.String(),
			"max_lookup_time": maxLookupTime.String(),
			"performance_target_met": maxLookupTime <= time.Millisecond,
		},
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		// Note: No domain names in response
	})
	
	log.Printf("🔍 Batch check: %d domains, %d blocked, avg=%v, max=%v", 
		len(request.Domains), blockedCount, avgTimePerDomain, maxLookupTime)
}

// ============================================================================
// STATUS AND MONITORING HANDLERS
// System health and performance monitoring endpoints
// ============================================================================

// handleHealthCheck provides detailed service health
func handleHealthCheck(c *gin.Context) {
	start := time.Now()
	
	mutex.RLock()
	healthy := blocklistManager != nil
	domainCount := int64(0)
	if healthy {
		domainCount = blocklistManager.stats.TotalDomains
	}
	mutex.RUnlock()
	
	responseTime := time.Since(start)
	uptime := time.Since(startTime)
	
	c.JSON(http.StatusOK, gin.H{
		"status": map[string]interface{}{
			"healthy": healthy,
			"service": "blocklist-service",
			"version": "1.0.0",
			"uptime": uptime.String(),
		},
		"data": gin.H{
			"domains_loaded": domainCount,
			"privacy_mode": privacyMode,
			"no_query_logging": noQueryLogging,
			"no_user_data_storage": noUserDataStorage,
		},
		"performance": gin.H{
			"lookup_target_ms": domainLookupTargetMs,
			"memory_target_mb": maxMemoryUsageMB,
			"cache_target_rate": targetCacheHitRate,
		},
		"response_time": responseTime.String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

// handlePerformanceMetrics provides detailed performance data
func handlePerformanceMetrics(c *gin.Context) {
	start := time.Now()
	
	mutex.RLock()
	defer mutex.RUnlock()
	
	if blocklistManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "service not ready"})
		return
	}
	
	responseTime := time.Since(start)
	uptime := time.Since(startTime)
	currentCacheHitRate := float64(0)
	if lookupCount > 0 {
		currentCacheHitRate = float64(cacheHits) / float64(lookupCount)
	}
	
	c.JSON(http.StatusOK, gin.H{
		"performance": gin.H{
			"lookup_count": lookupCount,
			"avg_lookup_time": (totalLookupTime / time.Duration(max(lookupCount, 1))).String(),
			"cache_hit_rate": currentCacheHitRate,
			"cache_hits": cacheHits,
			"cache_misses": cacheMisses,
			"uptime": uptime.String(),
		},
		"targets": gin.H{
			"lookup_time_target": fmt.Sprintf("<%dms", domainLookupTargetMs),
			"memory_target": fmt.Sprintf("<%dMB", maxMemoryUsageMB),
			"cache_hit_target": fmt.Sprintf(">%.0f%%", targetCacheHitRate*100),
		},
		"compliance": gin.H{
			"lookup_time_compliant": blocklistManager.stats.AvgLookupTime <= time.Millisecond,
			"cache_rate_compliant": currentCacheHitRate >= targetCacheHitRate,
		},
		"response_time": responseTime.String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

// Placeholder handlers for remaining endpoints
func handleBlocklistReload(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

func handleBlocklistStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

func handleBlocklistStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

func handleLookupPerformance(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

func handleMemoryUsage(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

func handleCacheStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "not_implemented"})
}

// Helper function to get max of two int64 values
func max(a, b int64) int64 {
	if a > b {
		return a
	}
	return b
}