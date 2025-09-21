# ECS Health Check Troubleshooting Guide

## Current Issue: Targets Draining

Based on the screenshot showing targets in "Initial" and "Draining" states, here are the most likely causes and solutions:

## Root Cause Analysis

The health check is failing because:

1. **Application Startup Issues**: The FastAPI app tries to connect to Supabase during startup, which may be failing
2. **Missing Environment Variables**: Critical environment variables might not be properly set
3. **Google Credentials**: The application expects Google credentials but they might not be available
4. **Network Connectivity**: The application might not be able to connect to external services

## Immediate Fixes Applied

### 1. Robust Startup Process
- Modified startup event to handle database connection failures gracefully
- Application will now start even if Supabase is temporarily unavailable
- Added try-catch blocks around settings initialization

### 2. Enhanced Health Check
- Improved `/health` endpoint with detailed status information
- Shows configuration status for all services
- Non-blocking connectivity tests

### 3. Environment Variables Cleanup
- Removed unused database variables (`DB_HOST`, `DB_NAME`, etc.)
- Kept only actively used variables
- Added Google credentials via AWS Secrets Manager

## Debugging Steps

### 1. Check ECS Service Logs
```bash
# Get the ECS service name
aws ecs list-services --cluster dil-fnd-ecs-fargate-cluster-v2

# Get task ARNs
aws ecs list-tasks --cluster dil-fnd-ecs-fargate-cluster-v2 --service-name dil-fnd-ai-tutor-service-v2

# Check task logs
aws logs get-log-events --log-group-name /ecs/dil-fnd-ai-tutor-service-v2 --log-stream-name <stream-name>
```

### 2. Test Health Check Manually
```bash
# Get the load balancer DNS name
aws elbv2 describe-load-balancers --names dil-fnd-fargate-lb-v2

# Test health check endpoint
curl -v http://<load-balancer-dns>/health
```

### 3. Check Task Definition Environment Variables
```bash
# Describe the task definition
aws ecs describe-task-definition --task-definition dil-fnd-ai-tutor-service-v2
```

## Common Issues and Solutions

### Issue 1: Missing Google Credentials
**Symptoms**: Application fails to start, logs show Google credentials errors
**Solution**: 
1. Ensure `GOOGLE_CREDENTIALS_JSON` is set in GitHub Secrets
2. Verify AWS Secrets Manager has the credentials
3. Check IAM permissions for ECS task to access secrets

### Issue 2: Supabase Connection Timeout
**Symptoms**: Health check fails, startup takes too long
**Solution**: 
1. Check Supabase URL and service key
2. Verify network connectivity from ECS tasks
3. Check security groups allow outbound HTTPS

### Issue 3: Redis Connection Issues
**Symptoms**: Redis errors in logs, health check shows Redis errors
**Solution**:
1. Verify MemoryDB cluster is running
2. Check security groups allow port 6379
3. Ensure ECS tasks are in correct subnets

### Issue 4: Health Check Timeout
**Symptoms**: Targets remain in "Initial" state
**Solution**:
1. Increase health check timeout (already set to 15s)
2. Increase grace period (already set to 60s)
3. Check if application is binding to correct port (8000)

## Verification Steps

### 1. Check Application Startup
```bash
# SSH into ECS task (if possible) or check logs
docker logs <container-id>

# Look for these startup messages:
# "🚀 [STARTUP] AI English Tutor Backend starting..."
# "✅ [STARTUP] Application started successfully"
```

### 2. Test Health Endpoint Locally
```bash
# If you can access the container directly
curl http://localhost:8000/health

# Should return JSON with status information
```

### 3. Verify Environment Variables
Check that these environment variables are set in the ECS task:
- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `ELEVEN_API_KEY`
- `ELEVEN_VOICE_ID`
- `WP_SITE_URL`
- `WP_API_USERNAME`
- `WP_API_APPLICATION_PASSWORD`
- `REDIS_HOST`
- `REDIS_PORT`
- `GOOGLE_APPLICATION_CREDENTIALS_JSON` (from secrets)

## Next Steps

1. **Deploy the fixes** using GitHub Actions
2. **Monitor the deployment** in ECS console
3. **Check CloudWatch logs** for startup messages
4. **Test health endpoint** once deployment completes
5. **Verify target health** in ALB console

## Expected Behavior After Fix

1. **Startup**: Application should start within 30-45 seconds
2. **Health Check**: `/health` endpoint should return 200 OK with detailed status
3. **Target Status**: Targets should move from "Initial" → "Healthy"
4. **Logs**: Should see successful startup messages without errors

## If Issues Persist

1. **Check AWS Secrets Manager**: Ensure Google credentials secret exists and is accessible
2. **Verify IAM Permissions**: ECS task execution role should have `secretsmanager:GetSecretValue`
3. **Network Configuration**: Verify security groups and NACLs
4. **Resource Limits**: Check if CPU/memory limits are sufficient
5. **Application Port**: Ensure FastAPI is binding to 0.0.0.0:8000, not localhost

## Monitoring Commands

```bash
# Watch ECS service events
aws ecs describe-services --cluster dil-fnd-ecs-fargate-cluster-v2 --services dil-fnd-ai-tutor-service-v2

# Monitor target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Stream CloudWatch logs
aws logs tail /ecs/dil-fnd-ai-tutor-service-v2 --follow
```

This troubleshooting guide should help identify and resolve the health check issues.
