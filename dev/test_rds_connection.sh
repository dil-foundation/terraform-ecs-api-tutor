#!/bin/bash

# Test RDS Connection Script
# This script tests connectivity to RDS from various methods

echo "🔍 Testing RDS Connection..."
echo ""

# RDS Configuration
RDS_ENDPOINT="pintb-instance.c348eg0merux.us-east-2.rds.amazonaws.com"
RDS_PORT="3306"
DB_USER="uatuser"
DB_PASSWORD="ChangeMe123!"
DB_NAME="uattenantdbservice"

echo "📊 RDS Configuration:"
echo "   Endpoint: $RDS_ENDPOINT"
echo "   Port: $RDS_PORT"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"
echo ""

# Test 1: Check if RDS endpoint is reachable via DNS
echo "🌐 Test 1: DNS Resolution"
if nslookup $RDS_ENDPOINT > /dev/null 2>&1; then
    echo "   ✅ DNS resolution successful"
    IP=$(nslookup $RDS_ENDPOINT | grep "Address:" | tail -1 | awk '{print $2}')
    echo "   📍 Resolved to IP: $IP"
else
    echo "   ❌ DNS resolution failed"
fi
echo ""

# Test 2: Check port connectivity (if nc is available)
echo "🔌 Test 2: Port Connectivity"
if command -v nc >/dev/null 2>&1; then
    if nc -z -w5 $RDS_ENDPOINT $RDS_PORT 2>/dev/null; then
        echo "   ✅ Port $RDS_PORT is open and reachable"
    else
        echo "   ❌ Port $RDS_PORT is not reachable"
    fi
else
    echo "   ⚠️  netcat (nc) not available, skipping port test"
fi
echo ""

# Test 3: Check if MySQL client is available
echo "🗄️  Test 3: MySQL Client Availability"
if command -v mysql >/dev/null 2>&1; then
    echo "   ✅ MySQL client is available"
    echo "   💡 You can test connection with:"
    echo "      mysql -h $RDS_ENDPOINT -P $RDS_PORT -u $DB_USER -p$DB_PASSWORD $DB_NAME"
else
    echo "   ❌ MySQL client not available"
    echo "   💡 Install with: brew install mysql-client (macOS) or apt-get install mysql-client (Ubuntu)"
fi
echo ""

# Test 4: Check AWS RDS instance status
echo "☁️  Test 4: AWS RDS Instance Status"
if command -v aws >/dev/null 2>&1; then
    echo "   Checking RDS instance status..."
    STATUS=$(aws rds describe-db-instances --db-instance-identifier pintb-instance --region us-east-2 --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null)
    if [ "$STATUS" = "available" ]; then
        echo "   ✅ RDS instance is available"
    else
        echo "   ⚠️  RDS instance status: $STATUS"
    fi
else
    echo "   ⚠️  AWS CLI not available, skipping status check"
fi
echo ""

# Test 5: Check bastion host connectivity
echo "🖥️  Test 5: Bastion Host Connectivity"
BASTION_IP="3.148.236.103"
if ping -c 1 -W 5 $BASTION_IP > /dev/null 2>&1; then
    echo "   ✅ Bastion host is reachable at $BASTION_IP"
else
    echo "   ❌ Bastion host is not reachable at $BASTION_IP"
fi
echo ""

echo "📋 Summary:"
echo "   To connect to RDS via bastion host:"
echo "   1. SSH to bastion: ssh -i ~/.ssh/uattenant-bastion-key ec2-user@$BASTION_IP"
echo "   2. From bastion: mysql -h $RDS_ENDPOINT -P $RDS_PORT -u $DB_USER -p$DB_PASSWORD $DB_NAME"
echo ""
echo "   Alternative: Use SSH tunnel:"
echo "   ssh -i ~/.ssh/uattenant-bastion-key -L 3306:$RDS_ENDPOINT:$RDS_PORT -N ec2-user@$BASTION_IP"
echo "   Then connect to: mysql -h 127.0.0.1 -P 3306 -u $DB_USER -p$DB_PASSWORD $DB_NAME"
