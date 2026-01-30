#!/bin/bash

# Deploy script for r107-garage-hub RSS ingestion with Gemini
# This script deploys the updated Edge Function to Supabase

set -e

echo "🚀 Deploying r107-garage-hub RSS ingestion with Gemini..."
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found!"
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Check if logged in
if ! supabase projects list &> /dev/null; then
    echo "🔐 Please login to Supabase first:"
    supabase login
fi

# Link project if not already linked
if [ ! -f ".supabase/config.toml" ]; then
    echo "🔗 Linking to Supabase project..."
    supabase link --project-ref xqsdepmtejvnngcnrklk
fi

# Set Gemini API key secret
echo "🔑 Setting GEMINI_API_KEY secret..."
GEMINI_KEY=$(grep GEMINI_API_KEY ~/Projekty/r107garage/.env-r107 | cut -d '=' -f2)

if [ -z "$GEMINI_KEY" ]; then
    echo "❌ GEMINI_API_KEY not found in .env-r107"
    echo "Please add it manually or provide it now:"
    read -p "Enter Gemini API Key: " GEMINI_KEY
fi

supabase secrets set GEMINI_API_KEY="$GEMINI_KEY"

echo ""
echo "📦 Deploying ingest-rss Edge Function..."
supabase functions deploy ingest-rss

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Next steps:"
echo "1. Test the function in your app's Admin panel"
echo "2. Check logs: https://supabase.com/dashboard/project/xqsdepmtejvnngcnrklk/logs/edge-functions"
echo "3. Verify price extraction from US listings"
echo ""
echo "🔍 To test manually:"
echo "   supabase functions invoke ingest-rss"
