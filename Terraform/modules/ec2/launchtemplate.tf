data "aws_ssm_parameter" "al2023_latest" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "wordpress_blog" {
  name          = "Wordpress-blog-temp"
  description   = "temporary blog template"
  image_id      = data.aws_ssm_parameter.al2023_latest.value
  instance_type = "t2.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    security_groups             = [aws_security_group.goingtointernet.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Wordpress-blog-temp"
    }
  }

  user_data = base64encode(<<-EOT
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting user data script at $(date) ==="

REGION="ap-southeast-1"
ACCOUNT_ID="516969219217"
ECR_REPO="wordpress-blog-ecr"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest"
EFS_MOUNT_PATH="/mnt/efs"

# --- Install packages ---
dnf -y update
dnf install -y docker amazon-efs-utils aws-cli jq
systemctl enable --now docker

# --- Wait for Docker daemon ---
for i in {1..30}; do
  docker info &>/dev/null && break
  sleep 2
done

# --- Fetch SSM parameters (fail if missing) ---
fetch_param() { aws ssm get-parameter --region "$REGION" --name "$1" --with-decryption --query 'Parameter.Value' --output text; }
fetch_param_plain() { aws ssm get-parameter --region "$REGION" --name "$1" --query 'Parameter.Value' --output text; }

DBPassword="$(fetch_param /BLOG/Wordpress/DBPassword)"
DBUser="$(fetch_param_plain /BLOG/Wordpress/DBUser)"
DBName="$(fetch_param_plain /BLOG/Wordpress/DBName)"
DBEndpoint="$(fetch_param_plain /BLOG/Wordpress/DBEndpoint)"
EFSFileSystemID="$(fetch_param_plain /BLOG/Wordpress/EFSFileSystemID)"
ALBDNSName="$(fetch_param_plain /BLOG/Wordpress/ALBDNSName)"

echo "ALB DNS: $ALBDNSName"
echo "DB endpoint: $DBEndpoint"
test -n "$DBPassword" -a -n "$DBUser" -a -n "$DBName" -a -n "$DBEndpoint" -a -n "$EFSFileSystemID" -a -n "$ALBDNSName"

# --- Mount EFS with retries ---
mkdir -p "$EFS_MOUNT_PATH"
for i in {1..10}; do
  if mount -t efs -o tls,_netdev "$EFSFileSystemID:/" "$EFS_MOUNT_PATH"; then
    echo "EFS mounted"
    break
  fi
  echo "EFS mount attempt $i failed; retrying..."
  sleep 3
done
mountpoint -q "$EFS_MOUNT_PATH" || { echo "EFS mount failed after retries"; exit 1; }

# Prepare wp-content and set ownership only there
mkdir -p "$EFS_MOUNT_PATH/wp-content"
chown -R 33:33 "$EFS_MOUNT_PATH/wp-content"
chmod -R 755 "$EFS_MOUNT_PATH/wp-content"

# --- Login to ECR and pull image ---
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
docker pull "$ECR_URI"

# --- Start WordPress container with CloudFront URLs ---
docker run -d \
  --name wordpress \
  --restart unless-stopped \
  -p 80:80 \
  -v "$EFS_MOUNT_PATH/wp-content:/var/www/html/wp-content:rw" \
  -e WORDPRESS_DB_HOST="$DBEndpoint" \
  -e WORDPRESS_DB_NAME="$DBName" \
  -e WORDPRESS_DB_USER="$DBUser" \
  -e WORDPRESS_DB_PASSWORD="$DBPassword" \
  -e WP_HOME="http://blog.baylenwebsite.xyz" \
  -e WP_SITEURL="http://blog.baylenwebsite.xyz" \
  "$ECR_URI"

# --- Wait for WordPress ---
echo "Waiting for WordPress to be ready..."
for i in {1..60}; do
  if curl -fsS --max-time 2 http://localhost/ >/dev/null 2>&1; then
    echo "WordPress is ready"
    break
  fi
  sleep 2
done

# --- Configure WordPress URLs for CloudFront ---
sleep 10
if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
  echo "Configuring WordPress for CloudFront..."
  # Force set the URLs to your custom domain
  docker exec wordpress wp option update home "http://blog.baylenwebsite.xyz" --allow-root
  docker exec wordpress wp option update siteurl "http://blog.baylenwebsite.xyz" --allow-root
  # Clear any redirect caches
  docker exec wordpress wp cache flush --allow-root || true
  echo "WordPress configured for CloudFront"
else
  echo "WordPress not installed yet - URLs set via environment variables"
fi

echo "=== Setup complete at $(date) ==="
docker ps
EOT
)
}