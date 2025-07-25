# GoalGetter GCP Infrastructure

This Terraform configuration sets up the complete infrastructure for the GoalGetter Flutter web application on Google Cloud Platform.

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** installed (version >= 1.0)
3. **GitHub repository** with your Flutter project
4. **GCP billing account** (if creating a new project)

## Setup Instructions

### 1. Configure Variables

Copy the example variables file and update it with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- `project_id`: Your GCP project ID
- `github_owner`: Your GitHub username
- `github_repo`: Your repository name
- `billing_account`: Your GCP billing account ID (if creating new project)

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. Connect GitHub Repository

After the infrastructure is created, you'll need to connect your GitHub repository to Cloud Build:

1. Go to the Google Cloud Console
2. Navigate to Cloud Build > Triggers
3. Find your trigger and click "Connect Repository"
4. Follow the instructions to connect your GitHub repository

## What Gets Created

- **GCP Project** (optional, if `create_project = true`)
- **Required APIs** enabled:
  - Cloud Build API
  - Cloud Run API
  - Container Registry API
  - Artifact Registry API
- **Cloud Build Trigger** that builds on push to main branch
- **Cloud Run Service** to host your Flutter web app
- **Public access** to the Cloud Run service

## Files Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Your specific values (create this)
├── terraform.tfvars.example  # Example values
└── README.md           # This file

cloudbuild.yaml         # Cloud Build configuration
Dockerfile              # Docker configuration for Flutter web
nginx.conf              # Nginx configuration
```

## Deployment Flow

1. Push code to `main` branch
2. Cloud Build trigger automatically starts
3. Docker image is built and pushed to Container Registry
4. Cloud Run service is updated with the new image
5. Your Flutter web app is live at the provided URL

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Notes

- The Cloud Run service is configured to scale to zero when not in use (cost optimization)
- The service is publicly accessible
- Static assets are cached for 1 year
- The configuration includes security headers

## Summary

I've created a complete Terraform setup for your GoalGetter Flutter project that includes:

1. **Dockerfile** - Properly configured for Flutter web builds
2. **nginx.conf** - Web server configuration with caching and security headers
3. **Terraform Configuration** - Creates project, APIs, Cloud Build trigger, and Cloud Run service
4. **Cloud Build Configuration** - Automatically builds and deploys on push to main
5. **Documentation** - Complete setup instructions

### Key Features:
- **Automatic deployments** on push to main branch
- **Cost optimization** with Cloud Run scaling to zero
- **Security headers** and proper caching
- **Public access** to your web app
- **Complete infrastructure as code**

### Next Steps:
1. Update the variables in `terraform/terraform.tfvars.example` with your specific values
2. Run `terraform init` and `terraform apply` in the terraform directory
3. Connect your GitHub repository to Cloud Build
4. Push to main to trigger your first deployment

The setup is ready for your current Flutter web app, and when you add an API and database later, you can easily extend the Terraform configuration to include those resources as well. 