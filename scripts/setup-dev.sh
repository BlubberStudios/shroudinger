#!/bin/bash

# Development Environment Setup Script
# Sets up the development environment for Shroudinger DNS App

echo "🔧 Setting up Shroudinger DNS development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script is designed for macOS only${NC}"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✅ Homebrew already installed${NC}"
fi

# Install Go
echo "📦 Installing Go..."
if command -v go &> /dev/null; then
    echo -e "${GREEN}✅ Go already installed ($(go version))${NC}"
else
    brew install go
    echo -e "${GREEN}✅ Go installed${NC}"
fi

# Install development tools
echo "🛠️  Installing development tools..."

# Install golangci-lint for Go linting
if command -v golangci-lint &> /dev/null; then
    echo -e "${GREEN}✅ golangci-lint already installed${NC}"
else
    brew install golangci-lint
    echo -e "${GREEN}✅ golangci-lint installed${NC}"
fi

# Install air for Go live reload (optional)
if command -v air &> /dev/null; then
    echo -e "${GREEN}✅ air already installed${NC}"
else
    brew install air
    echo -e "${GREEN}✅ air installed${NC}"
fi

# Check if Xcode is installed
if command -v xcodebuild &> /dev/null; then
    echo -e "${GREEN}✅ Xcode already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Xcode not found. Please install Xcode from the Mac App Store${NC}"
    echo "   After installation, run: xcode-select --install"
fi

# Check if Xcode Command Line Tools are installed
if xcode-select -p &> /dev/null; then
    echo -e "${GREEN}✅ Xcode Command Line Tools already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Installing Xcode Command Line Tools...${NC}"
    xcode-select --install
fi

# Install Docker (optional, for containerized development)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Docker not found. Installing Docker...${NC}"
    brew install --cask docker
    echo -e "${GREEN}✅ Docker installed${NC}"
fi

# Set up Go modules
echo "📋 Setting up Go modules..."
cd backend && go mod tidy
cd ../middleware && go mod tidy
cd ..

# Create necessary directories
echo "📁 Creating development directories..."
mkdir -p backend/bin
mkdir -p middleware/bin
mkdir -p logs
mkdir -p tmp

# Set up Git hooks (optional)
echo "🔧 Setting up Git hooks..."
if [ -d ".git" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run privacy audit before commits
./scripts/privacy-audit.sh
if [ $? -ne 0 ]; then
    echo "❌ Privacy audit failed. Commit aborted."
    exit 1
fi
EOF
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✅ Git pre-commit hook installed${NC}"
fi

# Create development configuration
echo "⚙️  Creating development configuration..."
cat > shared/configs/development.yaml << 'EOF'
# Development Configuration
server:
  host: localhost
  port: 8080
  
dns:
  servers:
    - name: "Cloudflare"
      address: "1.1.1.1"
      port: 853
      protocol: "dot"
    - name: "Quad9"
      address: "9.9.9.9"
      port: 853
      protocol: "dot"

blocklist:
  sources:
    - "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    - "https://someonewhocares.org/hosts/zero/hosts"
  
  update_interval: "24h"
  
logging:
  level: "debug"
  # Privacy: No user data logging
  no_query_logging: true
  no_domain_logging: true
EOF

echo "✅ Development environment setup complete!"
echo ""
echo "🚀 Next steps:"
echo "1. Run 'make dev-setup' to install additional dependencies"
echo "2. Run 'make dev' to start development services"
echo "3. Run 'make test' to run all tests"
echo "4. Run 'make privacy-audit' to verify privacy compliance"
echo ""
echo "📚 Available commands:"
echo "  make help  - Show all available commands"