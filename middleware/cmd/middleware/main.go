// Package main implements the middleware service for Shroudinger DNS App
// This service coordinates between the macOS NetworkExtension and backend services
// Privacy-first design: No DNS query logging, no domain persistence, no user tracking
package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	// Service configuration - middleware coordinates NetworkExtension
	defaultPort = "8083"
	serviceName = "middleware"
	// Testing configuration
	maxLogEntries = 100
)

func main() {
	// Initialize Gin router
	r := gin.Default()

	// Privacy-first middleware
	r.Use(privacyMiddleware())
	r.Use(corsMiddleware())
	if testingMode {
		r.Use(loggingMiddleware())
	}

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
	
	// Testing-only logging endpoints (disabled in production)
	if testingMode {
		testing := r.Group("/testing")
		{
			testing.GET("/logs", handleGetLogs)
			testing.DELETE("/logs", handleClearLogs)
			testing.GET("/logs/stream", handleLogsStream)
		}
		log.Println("🧪 Testing mode enabled - logging endpoints available")
	} else {
		log.Println("🔒 Production mode - logging endpoints disabled")
	}

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
		addLogEntry("INFO", "middleware", "service_started", 0, 0, nil)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			addLogEntry("ERROR", "middleware", "service_failed", 0, 0, err)
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
		// Core privacy headers - comprehensive privacy policy declaration
		c.Header("X-Privacy-Policy", "no-query-logging")
		c.Header("X-No-User-Tracking", "true")
		c.Header("X-No-Query-Logging", "true")
		c.Header("X-No-Domain-Logging", "true")
		c.Header("X-Data-Retention", "none")
		c.Header("X-Analytics-Disabled", "true")
		c.Header("X-Telemetry-Disabled", "true")
		
		// DNS privacy specific headers
		c.Header("X-DNS-Privacy", "encrypted-only")
		c.Header("X-DNS-Logging", "disabled")
		c.Header("X-DNS-Caching", "anonymous")
		
		// User privacy protection headers
		c.Header("X-IP-Logging", "disabled")
		c.Header("X-User-Agent-Logging", "disabled")
		c.Header("X-Session-Tracking", "disabled")
		
		// Data handling headers
		c.Header("X-Data-Storage", "memory-only")
		c.Header("X-Data-Persistence", "none")
		c.Header("X-Data-Sharing", "none")
		
		// Testing mode indicator
		if testingMode {
			c.Header("X-Testing-Mode", "true")
			c.Header("X-Testing-Logging", "non-sensitive-only")
		}
		
		// Remove identifying headers for privacy
		c.Header("Server", "Shroudinger-DNS-Privacy")
		c.Header("X-Powered-By", "")
		
		c.Next()
	}
}

// Testing-only logging middleware (privacy-safe)
func loggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !testingMode {
			c.Next()
			return
		}
		
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method
		
		c.Next()
		
		latency := time.Since(start)
		status := c.Writer.Status()
		
		// Log only non-sensitive request information
		event := method + " " + path
		addLogEntry("INFO", "middleware", event, status, latency, nil)
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
		addLogEntry("ERROR", "dns", "query_invalid_request", 400, 0, err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// PRIVACY CRITICAL: Process DNS query without logging the domain
	// The domain is handled in-memory only and never persisted anywhere
	
	// Log query processing (NO DOMAIN LOGGED)
	addLogEntry("INFO", "dns", "query_processed", 0, 0, nil)
	
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
		addLogEntry("ERROR", "extension", "register_invalid_request", 400, 0, err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	addLogEntry("INFO", "extension", "extension_registered", 200, 0, nil)
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

// Testing-only logging endpoints
func handleGetLogs(c *gin.Context) {
	if !testingMode {
		c.JSON(http.StatusForbidden, gin.H{"error": "Logging disabled in production"})
		return
	}
	
	logs := getLogEntries()
	c.JSON(http.StatusOK, gin.H{
		"logs":  logs,
		"count": len(logs),
		"max_entries": maxLogEntries,
		"testing_mode": testingMode,
	})
}

func handleClearLogs(c *gin.Context) {
	if !testingMode {
		c.JSON(http.StatusForbidden, gin.H{"error": "Logging disabled in production"})
		return
	}
	
	clearLogEntries()
	addLogEntry("INFO", "middleware", "logs_cleared", 200, 0, nil)
	c.JSON(http.StatusOK, gin.H{"message": "Logs cleared successfully"})
}

func handleLogsStream(c *gin.Context) {
	if !testingMode {
		c.JSON(http.StatusForbidden, gin.H{"error": "Logging disabled in production"})
		return
	}
	
	// Set headers for Server-Sent Events
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("Access-Control-Allow-Origin", "*")
	
	// Send initial logs
	logs := getLogEntries()
	for _, log := range logs {
		data, _ := json.Marshal(log)
		c.Writer.Write([]byte("data: " + string(data) + "\n\n"))
		c.Writer.Flush()
	}
	
	// Keep connection alive (simplified for demo)
	c.Writer.Write([]byte("data: {\"type\":\"stream_started\"}\n\n"))
	c.Writer.Flush()
}

var (
	startTime = time.Now()
	// Testing-only logging (disabled in production)
	testingMode = os.Getenv("SHROUDINGER_TESTING") == "true"
	logBuffer   = make([]LogEntry, 0, maxLogEntries)
	logMutex    sync.RWMutex
	// WebSocket connections for real-time logging
	logSubscribers = make(map[*http.ResponseWriter]bool)
	subscriberMutex sync.RWMutex
)

// LogEntry represents a testing log entry (no sensitive data)
type LogEntry struct {
	Timestamp    time.Time `json:"timestamp"`
	Level        string    `json:"level"`
	Service      string    `json:"service"`
	Event        string    `json:"event"`
	StatusCode   int       `json:"status_code,omitempty"`
	ResponseTime string    `json:"response_time,omitempty"`
	Error        string    `json:"error,omitempty"`
}

// addLogEntry adds a testing log entry (privacy-safe)
func addLogEntry(level, service, event string, statusCode int, responseTime time.Duration, err error) {
	if !testingMode {
		return
	}
	
	logMutex.Lock()
	defer logMutex.Unlock()
	
	entry := LogEntry{
		Timestamp:  time.Now(),
		Level:      level,
		Service:    service,
		Event:      event,
		StatusCode: statusCode,
	}
	
	if responseTime > 0 {
		entry.ResponseTime = responseTime.String()
	}
	
	if err != nil {
		entry.Error = err.Error()
	}
	
	// Maintain circular buffer
	if len(logBuffer) >= maxLogEntries {
		logBuffer = logBuffer[1:]
	}
	
	logBuffer = append(logBuffer, entry)
}

// getLogEntries returns testing log entries
func getLogEntries() []LogEntry {
	logMutex.RLock()
	defer logMutex.RUnlock()
	
	// Return a copy to prevent race conditions
	result := make([]LogEntry, len(logBuffer))
	copy(result, logBuffer)
	return result
}

// clearLogEntries clears all testing log entries
func clearLogEntries() {
	logMutex.Lock()
	defer logMutex.Unlock()
	
	logBuffer = logBuffer[:0]
}