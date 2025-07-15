// Package main implements the middleware service for Shroudinger DNS App
// This service coordinates between the macOS NetworkExtension and backend services
// Privacy-first design: No DNS query logging, no domain persistence, no user tracking
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	// Service configuration - middleware coordinates NetworkExtension
	defaultPort = "8083"
	serviceName = "middleware"
)

func main() {
	// Initialize Gin router
	r := gin.Default()

	// Privacy-first middleware
	r.Use(privacyMiddleware())
	r.Use(corsMiddleware())

	// Health check endpoint
	r.GET("/health", healthCheck)

	// API routes
	api := r.Group("/api/v1")
	{
		// DNS query processing (privacy-critical)
		api.POST("/dns/query", handleDNSQuery)
		api.POST("/dns/batch", handleDNSBatch)
		
		// NetworkExtension coordination
		api.POST("/extension/register", handleExtensionRegister)
		api.GET("/extension/status", handleExtensionStatus)
		
		// Service coordination
		api.GET("/services/health", handleServicesHealth)
		api.GET("/services/discover", handleServiceDiscovery)
	}

	// Performance monitoring
	r.GET("/metrics", handleMetrics)

	// Configure server
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// Start server
	go func() {
		log.Printf("🚀 Middleware Service starting on port %s", port)
		log.Printf("🔒 Privacy mode: No DNS query logging")
		log.Printf("🔗 NetworkExtension coordination enabled")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🔄 Middleware Service shutting down...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("❌ Server forced to shutdown: %v", err)
	}

	log.Println("✅ Middleware Service stopped")
}

// Privacy-first middleware - no logging of sensitive data
func privacyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Privacy-Policy", "no-query-logging")
		c.Header("X-No-Domain-Logging", "true")
		c.Header("X-Data-Retention", "none")
		c.Next()
	}
}

// CORS middleware
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	}
}

// Health check handler
func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": serviceName,
		"version": "1.0.0",
		"uptime":  time.Since(startTime).String(),
		"privacy": "no-query-logging",
	})
}

// DNS query processing handler (PRIVACY CRITICAL)
func handleDNSQuery(c *gin.Context) {
	var request struct {
		QueryID string `json:"query_id" binding:"required"`
		Domain  string `json:"domain" binding:"required"`
		Type    string `json:"type" binding:"required"`
		Source  string `json:"source"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// PRIVACY CRITICAL: Process DNS query without logging the domain
	// The domain is handled in-memory only and never persisted anywhere
	
	// Simulate DNS processing (in production, this would call backend services)
	response := gin.H{
		"query_id":      request.QueryID,
		"status":        "resolved",
		"blocked":       false,
		"response_time": "3ms",
		"resolver":      "encrypted",
		"cache_hit":     false,
		// NOTE: Domain is NOT included in response for privacy
	}

	c.JSON(http.StatusOK, response)
}

// Batch DNS processing handler
func handleDNSBatch(c *gin.Context) {
	var request struct {
		Queries []struct {
			QueryID string `json:"query_id"`
			Domain  string `json:"domain"`
			Type    string `json:"type"`
		} `json:"queries"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// Process batch queries
	var responses []gin.H
	for _, query := range request.Queries {
		response := gin.H{
			"query_id":      query.QueryID,
			"status":        "resolved",
			"blocked":       false,
			"response_time": "3ms",
		}
		responses = append(responses, response)
	}

	c.JSON(http.StatusOK, gin.H{"responses": responses})
}

// NetworkExtension registration handler
func handleExtensionRegister(c *gin.Context) {
	var request struct {
		ExtensionID  string   `json:"extension_id"`
		Version      string   `json:"version"`
		Capabilities []string `json:"capabilities"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":       "registered",
		"extension_id": request.ExtensionID,
		"version":      request.Version,
	})
}

// NetworkExtension status handler
func handleExtensionStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"extension_registered": true,
		"extension_active":     true,
		"dns_interception":     "enabled",
		"queries_processed":    1234,
		"last_activity":        time.Now().Format(time.RFC3339),
	})
}

// Service health coordination handler
func handleServicesHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"api_server":        "healthy",
		"blocklist_service": "healthy",
		"dns_service":       "healthy",
		"overall_status":    "healthy",
		"last_check":        time.Now().Format(time.RFC3339),
	})
}

// Service discovery handler
func handleServiceDiscovery(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"services": []gin.H{
			{"name": "api-server", "port": "8080", "status": "healthy"},
			{"name": "blocklist-service", "port": "8081", "status": "healthy"},
			{"name": "dns-service", "port": "8082", "status": "healthy"},
		},
	})
}

// Metrics handler
func handleMetrics(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"requests_per_second": 150,
		"avg_response_time":   "2ms",
		"memory_usage_mb":     45,
		"cpu_usage_percent":   8,
		"uptime":             time.Since(startTime).String(),
	})
}

var startTime = time.Now()