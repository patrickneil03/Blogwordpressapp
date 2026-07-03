resource "aws_launch_template" "wordpress_blog" {
  name          = "Wordpress-blog-temp"
  description   = "Launch template with pre-baked AMI"
  image_id      = aws_ami_from_instance.wordpress_ami.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    security_groups             = [aws_security_group.app.id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Wordpress-blog"
    }
  }

  user_data = base64encode(<<-EOT
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting FAST user data script at $(date) ==="
echo "Using pre-baked AMI - Docker, EFS utils, AWS CLI already installed!"

REGION="${var.region}"
ACCOUNT_ID="${var.account_id_output}"
ECR_REPO="wordpress-blog-ecr"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest"
EFS_MOUNT_PATH="/mnt/efs"

# --- Dynamic Domain Configuration Variable ---
DOMAIN_NAME="${var.route53_subdomain_name}"

# --- Start Docker (already installed in AMI) ---
systemctl start docker
echo "Docker started"

# --- Wait for Docker daemon ---
for i in {1..10}; do
  docker info &>/dev/null && break
  sleep 1
done
echo "Docker daemon ready"

# --- Fetch SSM parameters ---
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
for i in {1..5}; do
  if mount -t efs -o tls,_netdev "$EFSFileSystemID:/" "$EFS_MOUNT_PATH"; then
    echo "EFS mounted successfully"
    break
  fi
  echo "EFS mount attempt $i failed; retrying..."
  sleep 2
done
mountpoint -q "$EFS_MOUNT_PATH" || { echo "EFS mount failed after retries"; exit 1; }

# Prepare wp-content and set ownership only there
mkdir -p "$EFS_MOUNT_PATH/wp-content"
chown -R 33:33 "$EFS_MOUNT_PATH/wp-content"
chmod -R 755 "$EFS_MOUNT_PATH/wp-content"

# --- Login to ECR and pull image ---
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
docker pull "$ECR_URI"

# --- Start WordPress container with Dynamic Environment Coupling ---
docker run -d \
  --name wordpress \
  --restart unless-stopped \
  -p 80:80 \
  -v "$EFS_MOUNT_PATH/wp-content:/var/www/html/wp-content:rw" \
  -e WORDPRESS_DB_HOST="$DBEndpoint" \
  -e WORDPRESS_DB_NAME="$DBName" \
  -e WORDPRESS_DB_USER="$DBUser" \
  -e WORDPRESS_DB_PASSWORD="$DBPassword" \
  -e WORDPRESS_DOMAIN="$DOMAIN_NAME" \
  -e WP_HOME="https://$DOMAIN_NAME" \
  -e WP_SITEURL="https://$DOMAIN_NAME" \
  "$ECR_URI"

# --- Wait for WordPress ---
echo "Waiting for WordPress to be ready..."
for i in {1..30}; do
  if curl -fsS --max-time 2 http://localhost/health.php >/dev/null 2>&1; then
    echo "WordPress is ready"
    break
  fi
  sleep 2
done

# --- Configure WordPress URLs dynamically using WP-CLI ---
sleep 5
if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
  echo "Configuring WordPress options dynamically..."
  docker exec wordpress wp option update home "https://$DOMAIN_NAME" --allow-root
  docker exec wordpress wp option update siteurl "https://$DOMAIN_NAME" --allow-root
  docker exec wordpress wp cache flush --allow-root || true
  echo "WordPress database paths synchronized successfully."
else
  echo "WordPress not fully provisioned yet - environmental abstractions applied successfully"
fi

echo "=== FAST setup complete at $(date) ==="
docker ps
EOT
  )
}