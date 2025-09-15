# RDS Connection via Bastion Host

## Connection Information

### Bastion Host
- **Public IP**: `18.221.243.105`
- **SSH Command**: `ssh -i ~/.ssh/uattenant-bastion-key ec2-user@18.221.243.105`
- **User**: `ec2-user`

### RDS Database
- **Endpoint**: `pintb-instance.c348eg0merux.us-east-2.rds.amazonaws.com`
- **Port**: `3306`
- **Database Name**: `uattenantdbservice`
- **Username**: `uatuser`
- **Password**: `ChangeMe123!`

## Connection Methods

### Method 1: Direct SSH to Bastion (Recommended)
```bash
# Connect to bastion host
ssh -i ~/.ssh/uattenant-bastion-key ec2-user@18.221.243.105

# Once connected to bastion, connect to RDS
mysql -h pintb-instance.c348eg0merux.us-east-2.rds.amazonaws.com -P 3306 -u uatuser -p uattenantdbservice
# Enter password: ChangeMe123!
```

### Method 2: SSH Tunnel (if you have the key locally)
```bash
# Create SSH tunnel in one terminal
ssh -i ~/.ssh/uattenant-bastion-key -L 3306:pintb-instance.c348eg0merux.us-east-2.rds.amazonaws.com:3306 -N ec2-user@18.221.243.105

# In another terminal, connect to localhost
mysql -h 127.0.0.1 -P 3306 -u uatuser -p uattenantdbservice
```

### Method 3: Using the provided script
```bash
# Run the connection script
./connect_rds.sh
```

## Getting the SSH Key

If you don't have the SSH key, you can:

1. **Generate a new key pair** and update the bastion host
2. **Use AWS Systems Manager Session Manager** (if configured)
3. **Create a new bastion host** with your key

## Testing Connection

Once connected to MySQL, you can test with:
```sql
-- Show databases
SHOW DATABASES;

-- Use the application database
USE uattenantdbservice;

-- Show tables
SHOW TABLES;

-- Check if files table exists and has data
SELECT COUNT(*) FROM files;
```

## Troubleshooting

- **Connection refused**: Check if bastion host is running
- **Permission denied**: Verify SSH key permissions (chmod 600)
- **MySQL connection failed**: Check RDS security groups and bastion connectivity
