# Company Deployment Automation

This directory contains scripts and configurations for deploying new company instances of the Real Estate Management System.

## Prerequisites

1. **Accounts**
   - Netlify account (for frontend hosting)
   - Render.com account (for backend hosting)
   - Domain access (alphask.entorach.site)

2. **CLI Tools**
   - Netlify CLI (`npm install -g netlify-cli`)
   - Render CLI (install from [Render CLI Docs](https://render.com/docs/cli))
   - jq (`sudo apt-get install jq`)

## Deployment Process

### 1. Set Up a New Company

Run the deployment script to create a new company instance:

```bash
./scripts/deploy-company.sh \
  --company "Company Name" \
  --subdomain companyname \
  --admin admin@example.com
```

This will:
- Generate secure credentials
- Create a deployment directory with environment variables
- Provide next steps for deployment

### 2. Deploy Backend to Render

1. Log in to Render:
   ```bash
   render login
   ```

2. Deploy the backend:
   ```bash
   cd /path/to/real-estate-api
   render deploy --name api-<companyname> --env-file /path/to/deployment/<companyname>/.env
   ```

### 3. Deploy Frontend to Netlify

1. Log in to Netlify:
   ```bash
   netlify login
   ```

2. Deploy the frontend:
   ```bash
   cd /path/to/real-estate-dashboard
   netlify deploy --prod --dir=build
   ```

### 4. Configure DNS

Set up DNS records for the new subdomain:
- Create a CNAME record: `companyname.entorach.site` → `companyname.netlify.app`
- Create a CNAME record: `api-companyname.entorach.site` → `api-companyname.onrender.com`

## Environment Variables

Each company gets its own `.env` file with secure credentials:

```env
# Company: <Company Name>
NODE_ENV=production
PORT=3000
DB_NAME=companyname_db
DB_USER=postgres
DB_PASSWORD=<random-password>
JWT_SECRET=<random-secret>
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=<random-password>
CORS_ORIGINS=https://companyname.entorach.site
FRONTEND_URL=https://companyname.entorach.site
```

## Security Notes

- All credentials are automatically generated for each deployment
- Each company gets its own database with isolated credentials
- HTTPS is enforced for all communications
- CORS is strictly configured to only allow requests from the company's domain

## Troubleshooting

- **CORS Issues**: Verify the `CORS_ORIGINS` in the environment variables matches the frontend URL exactly
- **Database Connection**: Check the database credentials and ensure the database is accessible
- **Deployment Logs**: Check the logs in Render and Netlify dashboards for deployment errors

## Maintenance

To update a company's deployment:

1. Update the code in the main repository
2. Re-deploy the backend and frontend using the same process
3. The environment variables and database will be preserved

## Cleanup

To remove a company deployment:

1. Delete the deployment directory: `rm -rf /path/to/deployment/companyname`
2. Remove the services from Render and Netlify dashboards
3. Clean up DNS records

---

For support, contact the development team.
