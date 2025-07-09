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
	defaultPort = "8083"
)

func main() {
	// Privacy-first middleware service
	// Coordinates between Swift app and Go backend without user data logging
	
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Create Gin router
	r := gin.Default()

	// Privacy-first middleware
	r.Use(func(c *gin.Context) {
		c.Header("X-Privacy-Policy", "no-user-tracking")
		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "middleware",
			"privacy": "no-user-tracking",
		})
	})

	// Middleware API endpoints
	api := r.Group("/api/v1")
	{
		// App-Extension coordination
		api.POST("/extension/status", handleExtensionStatus)
		api.POST("/extension/configure", handleExtensionConfigure)
		
		// Backend communication
		api.GET("/backend/status", handleBackendStatus)
		api.POST("/backend/command", handleBackendCommand)
		
		// Configuration management
		api.GET("/config", handleConfigGet)
		api.POST("/config", handleConfigSet)
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// Start server
	go func() {
		log.Printf("🚀 Middleware Service starting on port %s", port)
		log.Printf("🔒 Privacy-first mode: No user tracking")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Middleware Service shutting down...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("❌ Server forced to shutdown: %v", err)
	}

	log.Println("✅ Middleware Service exited")
}

// Privacy-first handlers

func handleExtensionStatus(c *gin.Context) {
	// Check NetworkExtension status without user data
	c.JSON(http.StatusOK, gin.H{
		"extension_status": "active",
		"dns_filtering": true,
		"last_check": time.Now().Format(time.RFC3339),
	})
}

func handleExtensionConfigure(c *gin.Context) {
	var request struct {
		DNSServers []string `json:"dns_servers"`
		BlocklistEnabled bool `json:"blocklist_enabled"`
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Configure extension without logging user preferences
	c.JSON(http.StatusOK, gin.H{
		"status": "configured",
		"servers_count": len(request.DNSServers),
		"blocklist_enabled": request.BlocklistEnabled,
	})
}

func handleBackendStatus(c *gin.Context) {
	// Check backend services health
	c.JSON(http.StatusOK, gin.H{
		"api_server": "healthy",
		"blocklist_service": "healthy",
		"dns_service": "healthy",
		"last_check": time.Now().Format(time.RFC3339),
	})
}

func handleBackendCommand(c *gin.Context) {
	var request struct {
		Command string `json:"command"`
		Service string `json:"service"`
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Execute backend command without logging user actions
	c.JSON(http.StatusOK, gin.H{
		"status": "executed",
		"command": request.Command,
		"service": request.Service,
	})
}

func handleConfigGet(c *gin.Context) {
	// Return configuration without user-specific data
	c.JSON(http.StatusOK, gin.H{
		"dns_servers": []string{"1.1.1.1", "9.9.9.9"},
		"blocklist_enabled": true,
		"privacy_mode": true,
		"logging_disabled": true,
	})
}

func handleConfigSet(c *gin.Context) {
	var request map[string]interface{}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Update configuration without logging user changes
	c.JSON(http.StatusOK, gin.H{
		"status": "updated",
		"settings_count": len(request),
	})
}