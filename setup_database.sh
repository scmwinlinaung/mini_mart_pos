#!/bin/bash

# Mini Mart POS Database Setup Script
# This script will: 1. Start PostgreSQL container, 2. Drop old database, 3. Create new database, 4. Apply schema

echo "🏪 Mini Mart POS Database Setup"
echo "================================"

# Step 1: Start PostgreSQL container
echo "📦 Starting PostgreSQL container..."
docker-compose down
docker-compose up -d postgres

if [ $? -ne 0 ]; then
    echo "❌ Failed to start PostgreSQL container"
    exit 1
fi

echo "✅ PostgreSQL container started successfully"
echo "⏳ Waiting for database to be ready..."
sleep 5

# Step 2: Drop existing database (if it exists)
echo "🗑️  Dropping existing database (if any)..."
docker exec -i mini_mart_pos_db psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS mini_mart_pos;"

if [ $? -eq 0 ]; then
    echo "✅ Database dropped (or didn't exist)"
else
    echo "⚠️  Warning: Could not drop database (may not exist)"
fi

# Step 3: Create new database
echo "🆕 Creating new database..."
docker exec -i mini_mart_pos_db psql -U postgres -d postgres -c "CREATE DATABASE mini_mart_pos;"

if [ $? -ne 0 ]; then
    echo "❌ Failed to create database"
    exit 1
fi

echo "✅ Database 'mini_mart_pos' created successfully"

# Step 4: Apply schema
echo "🏗️  Applying database schema..."
docker exec -i mini_mart_pos_db psql -U postgres -d mini_mart_pos < ./schema.sql

if [ $? -ne 0 ]; then
    echo "❌ Failed to apply schema"
    exit 1
fi

echo "✅ Database schema applied successfully"

# Step 5: Verify setup
echo "🔍 Verifying database setup..."
TABLE_COUNT=$(docker exec -i mini_mart_pos_db psql -U postgres -d mini_mart_pos -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

echo "✅ Database setup complete!"
echo "📊 Total tables created: $TABLE_COUNT"

# Show connection info
echo ""
echo "🔗 Database Connection Info:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: mini_mart_pos"
echo "   Username: postgres"
echo "   Password: postgres"
echo ""
echo "🎯 Ready to connect your Mini Mart POS application!"
echo "🚀 Run 'flutter pub get && flutter run' to start the app"