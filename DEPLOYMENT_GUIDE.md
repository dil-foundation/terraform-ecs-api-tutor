# AI Tutor ECS Deployment Guide

## Overview

This guide covers the deployment of the AI Tutor API to AWS ECS using Terraform, with fixes for health check failures and proper Google credentials management.

## Changes Made

### 1. Health Check Fixes
- **Increased health check grace period** from 10 to 60 seconds to allow proper application startup
- **Improved ALB health check tolerance** by increasing unhealthy threshold from 3 to 5 and timeout from 10 to 15 seconds
- **Health check endpoint** remains `/health` as configured in the FastAPI application

### 2. Task Definition Cleanup
Removed unused environment variables and kept only the active ones based on the application code:

**Active Environment Variables:**
- `OPENAI_API_KEY` - OpenAI API key for AI services
- `ELEVEN_API_KEY` - ElevenLabs API key for text-to-speech
- `ELEVEN_VOICE_ID` - ElevenLabs voice ID
- `SUPABASE_URL` - Supabase database URL
- `SUPABASE_SERVICE_KEY` - Supabase service key
- `WP_SITE_URL` - WordPress site URL
- `WP_API_USERNAME` - WordPress API username
- `WP_API_APPLICATION_PASSWORD` - WordPress application password
- `REDIS_HOST` - Redis host (MemoryDB endpoint)
- `REDIS_PORT` - Redis port (6379)
- `ENVIRONMENT` - Application environment (set to "production")

**Removed Variables:**
- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` (not used in current code)
- `REDIS_URL` (redundant with REDIS_HOST/PORT)

### 3. Google Credentials Integration
- **Added AWS Secrets Manager** for storing Google Cloud Service Account credentials
- **Updated task definition** to load credentials from AWS Secrets Manager as `GOOGLE_APPLICATION_CREDENTIALS_JSON`
- **Added IAM permissions** for ECS tasks to access the secrets
- **Updated GitHub Actions** to pass Google credentials from GitHub Secrets

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** v1.5.0 or later
3. **GitHub repository** with Actions enabled
4. **Google Cloud Service Account** JSON file

## Setup Instructions

### 1. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
AWS_ACCESS_KEY - AWS access key for Terraform
AWS_SECRET_ACCESS_KEY - AWS secret access key for Terraform
SUPABASE_URL - Your Supabase project URL
SUPABASE_SERVICE_KEY - Your Supabase service key
OPENAI_API_KEY - Your OpenAI API key
ELEVEN_API_KEY - Your ElevenLabs API key
ELEVEN_VOICE_ID - Your ElevenLabs voice ID
WP_SITE_URL - Your WordPress site URL
WP_API_USERNAME - Your WordPress API username
WP_API_APPLICATION_PASSWORD - Your WordPress application password
GOOGLE_CREDENTIALS_JSON - Your Google Cloud Service Account JSON (as string)
```

### 2. Google Credentials Setup

1. **Create a Service Account** in Google Cloud Console
2. **Download the JSON key file**
3. **Convert to single line** and add to GitHub Secrets as `GOOGLE_CREDENTIALS_JSON`

Example of converting JSON to single line:
```bash
cat google-credentials.json | jq -c . | tr -d '\n'
```

### 3. Local Development (Optional)

If deploying locally, create `terraform.tfvars`:

```hcl
# Copy from terraform.tfvars.example and fill in your values
supabase_url         = "https://your-project.supabase.co"
supabase_service_key = "your-supabase-service-key"
openai_api_key       = "sk-your-openai-api-key"
eleven_api_key       = "sk_your-elevenlabs-api-key"
eleven_voice_id      = "your-voice-id"
wp_site_url                 = "https://your-wordpress-site.com"
wp_api_username             = "your-wp-api-username"
wp_api_application_password = "your-wp-application-password"
google_credentials_json = "{\"type\":\"service_account\",\"project_id\":\"your-project\",...}"
```

### 4. Deployment

#### Via GitHub Actions (Recommended)
1. Push changes to your repository
2. Go to Actions tab in GitHub
3. Run "Dev-Terraform-Plan" workflow to review changes
4. Run "Dev-Terraform-Apply" workflow to deploy

#### Manual Deployment
```bash
cd dev
terraform init
terraform plan
terraform apply
```

## Architecture Changes

### AWS Resources Added
- **AWS Secrets Manager Secret** for Google credentials
- **IAM Policy** for ECS tasks to access secrets
- **IAM Role Policy Attachment** for secrets access

### Security Improvements
- Google credentials no longer hardcoded in container
- Sensitive data stored in AWS Secrets Manager
- Proper IAM permissions for secret access

## Troubleshooting

### Health Check Failures
1. **Check application logs** in CloudWatch
2. **Verify environment variables** are properly set
3. **Ensure Google credentials** are valid JSON
4. **Check Redis connectivity** to MemoryDB

### Common Issues
1. **Invalid Google credentials** - Verify JSON format and permissions
2. **Missing environment variables** - Check GitHub Secrets configuration
3. **Network connectivity** - Verify security groups and subnets
4. **Resource limits** - Check CPU/memory allocation

### Health Check Endpoints
- Primary: `http://container:8000/health`
- Alternative: `http://container:8000/api/healthcheck`

## Monitoring

- **CloudWatch Logs**: `/ecs/dil-fnd-ai-tutor-service-v2`
- **ECS Service**: `dil-fnd-ecs-fargate-cluster-v2`
- **Load Balancer**: `dil-fnd-fargate-lb-v2`
- **Target Group**: Health check status in AWS Console

## Next Steps

1. **Monitor deployment** for successful health checks
2. **Test API endpoints** through the load balancer
3. **Set up CloudWatch alarms** for monitoring
4. **Configure auto-scaling** based on load

## Support

For issues with this deployment:
1. Check CloudWatch logs for application errors
2. Verify all GitHub Secrets are properly configured
3. Ensure Google Cloud Service Account has necessary permissions
4. Review AWS ECS service events for deployment issues
