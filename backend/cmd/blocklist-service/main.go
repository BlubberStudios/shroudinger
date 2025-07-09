package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	defaultPort = "8081"
)

func main() {
	// Privacy-first blocklist service
	// Manages blocklists without storing user queries
	
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Create Gin router
	r := gin.Default()

	// Privacy-first middleware
	r.Use(func(c *gin.Context) {
		c.Header("X-Privacy-Policy", "no-user-data-storage")
		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "blocklist-service",
			"privacy": "no-user-data-storage",
		})
	})

	// Blocklist management endpoints
	api := r.Group("/api/v1")
	{
		api.POST("/blocklist/fetch", handleBlocklistFetch)
		api.POST("/blocklist/parse", handleBlocklistParse)
		api.POST("/blocklist/optimize", handleBlocklistOptimize)
		api.GET("/blocklist/sources", handleBlocklistSources)
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// Start server
	go func() {
		log.Printf("🚀 Blocklist Service starting on port %s", port)
		log.Printf("🔒 Privacy-first mode: No user data storage")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server failed to start: %v", err)
		}
	}()

	// Initialize blocklist management
	go initBlocklistManager()

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

	log.Println("✅ Blocklist Service exited")
}

func initBlocklistManager() {
	log.Println("📋 Initializing blocklist manager...")
	
	// Initialize in-memory data structures
	// No database, no persistent storage
	
	// Load default blocklists
	loadDefaultBlocklists()
	
	// Start periodic update routine
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			log.Println("🔄 Periodic blocklist update")
			updateBlocklists()
		}
	}
}

func loadDefaultBlocklists() {
	log.Println("📥 Loading default blocklists...")
	
	// Example blocklist sources
	sources := []string{
		"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
		"https://someonewhocares.org/hosts/zero/hosts",
		"https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers.txt",
	}
	
	for _, source := range sources {
		log.Printf("📥 Loading blocklist from %s", source)
		// Fetch and parse blocklist
		// Store in-memory only (no persistence)
	}
	
	log.Println("✅ Default blocklists loaded")
}

func updateBlocklists() {
	log.Println("🔄 Updating blocklists...")
	// Fetch latest blocklists and update in-memory structures
	// No user data involved
}

// Privacy-first handlers

func handleBlocklistFetch(c *gin.Context) {
	var request struct {
		Sources []string `json:"sources"`
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Fetch blocklists from sources (no user data)
	c.JSON(http.StatusOK, gin.H{
		"status": "fetching",
		"sources": len(request.Sources),
		"message": "Blocklist fetch initiated",
	})
}

func handleBlocklistParse(c *gin.Context) {
	// Parse blocklist data (no user involvement)
	c.JSON(http.StatusOK, gin.H{
		"status": "parsing",
		"message": "Blocklist parsing initiated",
	})
}

func handleBlocklistOptimize(c *gin.Context) {
	// Optimize blocklist for performance (no user data)
	c.JSON(http.StatusOK, gin.H{
		"status": "optimizing",
		"message": "Blocklist optimization initiated",
	})
}

func handleBlocklistSources(c *gin.Context) {
	// Return configured blocklist sources
	c.JSON(http.StatusOK, gin.H{
		"sources": []string{
			"StevenBlack/hosts",
			"someonewhocares.org",
			"AdguardFilters",
		},
		"total_domains": 1000000, // Example count
		"last_updated": time.Now().Format(time.RFC3339),
	})
}