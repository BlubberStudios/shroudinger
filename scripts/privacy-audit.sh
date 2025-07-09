#!/bin/bash

# Privacy Audit Script for Shroudinger DNS App
# Ensures no user data retention or logging

echo "🔒 Privacy Audit: Checking for user data retention..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

AUDIT_FAILED=false

# Check for DNS query logging
echo "📋 Checking for DNS query logging..."
if grep -r --exclude-dir=bin --exclude="*.sum" "log\..*query\|logger\..*query" backend/ middleware/ 2>/dev/null | grep -v "// No.*query.*logging" | grep -v "No query logging" | grep -v "without logging" | grep -v "no.*logging"; then
    echo -e "${RED}❌ WARNING: DNS query logging found!${NC}"
    AUDIT_FAILED=true
else
    echo -e "${GREEN}✅ No DNS query logging detected${NC}"
fi

# Check for domain name storage
echo "📋 Checking for domain name storage..."
if grep -r --exclude-dir=bin --exclude="*.sum" "store.*domain\|save.*domain\|persist.*domain" backend/ middleware/ 2>/dev/null | grep -v "// No.*domain.*storage" | grep -v "no.*domain.*storage"; then
    echo -e "${RED}❌ WARNING: Domain name storage found!${NC}"
    AUDIT_FAILED=true
else
    echo -e "${GREEN}✅ No domain name storage detected${NC}"
fi

# Check for database usage
echo "📋 Checking for database usage..."
if grep -r --exclude-dir=bin --exclude="*.sum" "database\|sql\|db\." backend/ middleware/ 2>/dev/null | grep -v "// No database" | grep -v "comment" | grep -v "no.*database"; then
    echo -e "${RED}❌ WARNING: Database usage found!${NC}"
    AUDIT_FAILED=true
else
    echo -e "${GREEN}✅ No database usage detected${NC}"
fi

# Check for user tracking
echo "📋 Checking for user tracking..."
if grep -r --exclude-dir=bin --exclude="*.sum" "track.*user\|analytics\|telemetry" backend/ middleware/ 2>/dev/null | grep -v "// No.*user.*tracking" | grep -v "no.*user.*tracking"; then
    echo -e "${RED}❌ WARNING: User tracking found!${NC}"
    AUDIT_FAILED=true
else
    echo -e "${GREEN}✅ No user tracking detected${NC}"
fi

# Check for persistent storage
echo "📋 Checking for persistent storage..."
if grep -r --exclude-dir=bin --exclude="*.sum" "persist\|save\|write.*file" backend/ middleware/ 2>/dev/null | grep -v "config\|log\|error" | grep -v "// No persistence" | grep -v "never persisted" | grep -v "no.*persistent" | grep -v "in-memory only"; then
    echo -e "${YELLOW}⚠️  Persistent storage detected - verify it's configuration only${NC}"
else
    echo -e "${GREEN}✅ No persistent storage of user data detected${NC}"
fi

# Check for memory leaks (potential data retention)
echo "📋 Checking for potential memory leaks..."
if grep -r --exclude-dir=bin --exclude="*.sum" "global.*map\|global.*slice" backend/ middleware/ 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Global data structures detected - verify they don't retain user data${NC}"
else
    echo -e "${GREEN}✅ No global data structures detected${NC}"
fi

# Check for proper cleanup
echo "📋 Checking for proper cleanup..."
if ! grep -r "defer.*close\|defer.*cleanup" backend/ middleware/ 2>/dev/null >/dev/null; then
    echo -e "${YELLOW}⚠️  Limited cleanup code detected - verify resources are properly released${NC}"
fi

# Check for encryption of stored data
echo "📋 Checking for encryption of any stored data..."
if grep -r --exclude-dir=bin --exclude="*.sum" "\.Store\|\.Save\|\.Persist" backend/ middleware/ 2>/dev/null | grep -v "encrypt\|crypto" | grep -v "never persisted" | grep -v "// No.*storage" | grep -v "no.*storage" | grep -v "in-memory only" | grep -v "Note: No"; then
    echo -e "${YELLOW}⚠️  Unencrypted storage detected - verify no sensitive data is stored${NC}"
else
    echo -e "${GREEN}✅ No unencrypted sensitive data storage detected${NC}"
fi

# Final audit result
echo ""
if [ "$AUDIT_FAILED" = true ]; then
    echo -e "${RED}❌ PRIVACY AUDIT FAILED: Fix the issues above before deploying${NC}"
    exit 1
else
    echo -e "${GREEN}✅ PRIVACY AUDIT PASSED: No user data retention detected${NC}"
    echo -e "${GREEN}🔒 Privacy guarantees maintained${NC}"
    exit 0
fi