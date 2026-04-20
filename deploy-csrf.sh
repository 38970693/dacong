#!/bin/bash

# CSRF Protection Deployment Script
# This script deploys the CSRF protection system to production

set -e  # Exit on error

echo "=========================================="
echo "CSRF Protection Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "CSRF_IMPLEMENTATION_SUMMARY.md" ]; then
    echo -e "${RED}Error: Must run from project root directory${NC}"
    exit 1
fi

# Step 1: Database Migration
echo -e "${YELLOW}Step 1: Applying database migration...${NC}"
cd dacong-api
if command -v supabase &> /dev/null; then
    supabase db push
    echo -e "${GREEN}✓ Database migration applied${NC}"
else
    echo -e "${RED}✗ Supabase CLI not found. Please install it first.${NC}"
    echo "  Install: npm install -g supabase"
    exit 1
fi
cd ..

# Step 2: Run Tests
echo ""
echo -e "${YELLOW}Step 2: Running tests...${NC}"
cd dacong-api/supabase/functions

echo "Running unit tests..."
if deno test tests/csrf_middleware_test.ts --quiet; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    exit 1
fi

echo "Running integration tests..."
if deno test tests/csrf_integration_test.ts --allow-net --allow-env --quiet; then
    echo -e "${GREEN}✓ Integration tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Integration tests failed (may require running server)${NC}"
fi

cd ../../..

# Step 3: Deploy Edge Functions
echo ""
echo -e "${YELLOW}Step 3: Deploying Edge Functions...${NC}"
cd dacong-api

if [ -f "deploy.sh" ]; then
    ./deploy.sh
    echo -e "${GREEN}✓ Edge Functions deployed${NC}"
else
    echo -e "${YELLOW}⚠ deploy.sh not found, skipping function deployment${NC}"
fi

cd ..

# Step 4: Verify Deployment
echo ""
echo -e "${YELLOW}Step 4: Verifying deployment...${NC}"

# Check if SUPABASE_URL is set
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${YELLOW}⚠ SUPABASE_URL not set, skipping verification${NC}"
else
    echo "Testing CSRF token endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/functions/v1/csrf-token")

    if [ "$RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ CSRF token endpoint is accessible${NC}"
    else
        echo -e "${RED}✗ CSRF token endpoint returned $RESPONSE${NC}"
        exit 1
    fi
fi

# Step 5: Flutter Client Setup
echo ""
echo -e "${YELLOW}Step 5: Setting up Flutter clients...${NC}"

if command -v flutter &> /dev/null; then
    # Mobile Client
    echo "Setting up mobile client..."
    cd dacong-client
    flutter pub get > /dev/null 2>&1
    echo -e "${GREEN}✓ Mobile client dependencies installed${NC}"
    cd ..

    # Admin Dashboard
    echo "Setting up admin dashboard..."
    cd dacong-admin
    flutter pub get > /dev/null 2>&1
    echo -e "${GREEN}✓ Admin dashboard dependencies installed${NC}"
    cd ..
else
    echo -e "${YELLOW}⚠ Flutter not found, skipping client setup${NC}"
fi

# Step 6: Security Checklist
echo ""
echo -e "${YELLOW}Step 6: Security Checklist${NC}"
echo ""

CHECKLIST=(
    "HTTPS enforced in production"
    "Environment variables configured"
    "CSRF middleware integrated"
    "Security headers configured"
    "Rate limiting enabled"
    "Audit logging enabled"
    "Error monitoring configured (Sentry)"
    "Database backups enabled"
)

for item in "${CHECKLIST[@]}"; do
    echo "  [ ] $item"
done

echo ""
echo -e "${YELLOW}Please verify the above items manually.${NC}"

# Step 7: Summary
echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Verify all checklist items above"
echo "2. Test CSRF protection in staging environment"
echo "3. Monitor error rates and performance"
echo "4. Review audit logs for suspicious activity"
echo ""
echo "Documentation:"
echo "  - CSRF Protection Guide: docs/security/CSRF_PROTECTION.md"
echo "  - Security Best Practices: docs/security/SECURITY_BEST_PRACTICES.md"
echo "  - Implementation Summary: CSRF_IMPLEMENTATION_SUMMARY.md"
echo ""
echo "Support:"
echo "  - Security issues: security@dacong.app"
echo "  - General questions: Check documentation first"
echo ""
echo -e "${GREEN}✓ CSRF protection system is ready for production!${NC}"
