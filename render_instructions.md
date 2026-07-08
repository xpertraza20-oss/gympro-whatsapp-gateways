# Deploying backend to Render

Follow these simple steps to deploy your backend to Render.com:

## Step 1: Create a GitHub Repository
1. Go to [GitHub](https://github.com) and create a **new repository** (Public or Private).
2. Name it whatever you like (e.g., `grocery-delivery-system`).
3. Leave it empty (do NOT initialize with README, .gitignore, or license).

## Step 2: Push your local code to GitHub
Run these commands in your VS Code terminal (or standard terminal) from the root folder (`e:/grocery-delivery-system`):

```bash
# 1. Rename branch to main
git branch -M main

# 2. Add remote origin (replace URL with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 3. Push the code
git push -u origin main
```

## Step 3: Create Web Service on Render
1. Go to [Render Dashboard](https://dashboard.render.com/web/new).
2. Connect your GitHub account and select your repository `grocery-delivery-system`.
3. Configure the settings:
   - **Name**: `grocery-delivery-backend`
   - **Root Directory**: `backend` (⚠️ Very Important!)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node index.js`
4. Add the following **Environment Variables** in Render's configuration:
   - `DATABASE_URL` = `postgresql://neondb_owner:npg_brcfN7F6WGEP@ep-damp-rain-asq4h4hp-pooler.c-4.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require`
   - `NODE_ENV` = `production`
   - `R2_ACCOUNT_ID` = `mock_account_id`
   - `R2_ACCESS_KEY_ID` = `mock_access_key_id`
   - `R2_SECRET_ACCESS_KEY` = `mock_secret_access_key`
   - `R2_BUCKET_NAME` = `mock_bucket_name`
   - `R2_PUBLIC_URL` = `https://mock_bucket_domain.r2.dev`
5. Click **Create Web Service**.

Once the deployment finishes, copy the URL of your Render service (e.g., `https://grocery-delivery-backend.onrender.com`) and paste it in the **Settings** tab of your Admin Panel!
