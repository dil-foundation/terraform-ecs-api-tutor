#!/bin/bash

# Package Lambda function for API Gateway proxy
echo "📦 Packaging Lambda function for API Gateway proxy..."

# Create temporary directory
mkdir -p temp_lambda

# Copy Lambda function code
cp lambda_proxy.py temp_lambda/index.py

# Install dependencies
cd temp_lambda
pip install urllib3 -t .

# Create zip file
zip -r ../api_proxy.zip .

# Clean up
cd ..
rm -rf temp_lambda

echo "✅ Lambda function packaged as api_proxy.zip"
