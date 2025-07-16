# Shroudinger DNS Privacy App - Monorepo Makefile
# Privacy-first macOS DNS blocklist application

.PHONY: all build test clean setup dev-setup docker-build help

# Default target
all: build

# Build all components
build:
	@echo "🏗️  Building all components..."
	@echo "📱 Building Swift frontend..."
	cd frontend && xcodebuild -project ShroudingerApp.xcodeproj -scheme ShroudingerApp -configuration Release
	@echo "🔧 Building Go middleware..."
	cd middleware && go build -o bin/middleware ./cmd/middleware
	@echo "⚙️  Building Go backend..."
	cd backend && go build -o bin/api-server ./cmd/api-server
	cd backend && go build -o bin/blocklist-service ./cmd/blocklist-service
	cd backend && go build -o bin/dns-service ./cmd/dns-service
	@echo "✅ Build complete!"

# Run tests for all components
test:
	@echo "🧪 Running all tests..."
	@echo "📱 Testing Swift frontend..."
	cd frontend && xcodebuild test -project ShroudingerApp.xcodeproj -scheme ShroudingerApp
	@echo "🔧 Testing Go middleware..."
	cd middleware && go test -v ./...
	@echo "⚙️  Testing Go backend..."
	cd backend && go test -v ./...
	@echo "✅ All tests passed!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	cd frontend && xcodebuild clean
	cd middleware && go clean && rm -rf bin/
	cd backend && go clean && rm -rf bin/
	@echo "✅ Clean complete!"

# Development setup
dev-setup:
	@echo "🔧 Setting up development environment..."
	@echo "📋 Installing Go dependencies..."
	cd middleware && go mod tidy
	cd backend && go mod tidy
	@echo "🍺 Installing development tools..."
	brew install go || echo "Go already installed"
	brew install golangci-lint || echo "golangci-lint already installed"
	@echo "✅ Development setup complete!"

# Start development services
dev:
	@echo "🚀 Starting development services..."
	@./scripts/start-services.sh
	@echo "✅ Development services started!"

# Stop development services
dev-stop:
	@echo "🛑 Stopping development services..."
	@./scripts/stop-services.sh
	@echo "✅ Development services stopped!"

# Run linting
lint:
	@echo "🔍 Running linters..."
	cd middleware && golangci-lint run
	cd backend && golangci-lint run
	@echo "✅ Linting complete!"

# Run privacy audit
privacy-audit:
	@echo "🔒 Running privacy audit..."
	./scripts/privacy-audit.sh
	@echo "✅ Privacy audit complete!"

# Create production build
build-prod:
	@echo "📦 Building production version..."
	cd frontend && xcodebuild -project ShroudingerApp.xcodeproj -scheme ShroudingerApp -configuration Release -archivePath build/ShroudingerApp.xcarchive archive
	cd middleware && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/middleware ./cmd/middleware
	cd backend && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/api-server ./cmd/api-server
	cd backend && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/blocklist-service ./cmd/blocklist-service
	cd backend && CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/dns-service ./cmd/dns-service
	@echo "✅ Production build complete!"

# Docker build
docker-build:
	@echo "🐳 Building Docker images..."
	cd backend && docker build -t shroudinger/backend:latest .
	cd middleware && docker build -t shroudinger/middleware:latest .
	@echo "✅ Docker build complete!"

# Health check
health:
	@echo "🏥 Running health checks..."
	curl -f http://localhost:8080/health || echo "❌ API server not responding"
	curl -f http://localhost:8081/health || echo "❌ Blocklist service not responding"
	curl -f http://localhost:8082/health || echo "❌ DNS service not responding"
	curl -f http://localhost:8083/health || echo "❌ Middleware not responding"
	@echo "✅ Health check complete!"

# Help
help:
	@echo "📚 Available commands:"
	@echo "  build         - Build all components"
	@echo "  test          - Run all tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  dev-setup     - Set up development environment"
	@echo "  dev           - Start development services"
	@echo "  dev-stop      - Stop development services"
	@echo "  lint          - Run linters"
	@echo "  privacy-audit - Run privacy audit"
	@echo "  build-prod    - Create production build"
	@echo "  docker-build  - Build Docker images"
	@echo "  health        - Run health checks"
	@echo "  help          - Show this help"