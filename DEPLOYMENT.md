# RC Hub Deployment Guide

This document provides instructions for deploying the RC Hub application to Vercel.

## Prerequisites

- Vercel account
- Supabase account with project set up
- Node.js and npm installed

## Deployment Steps

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Login to Vercel:
```bash
vercel login
```

3. Set up environment variables in Vercel:
```bash
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
```

4. Deploy the application:
```bash
cd rc_hub
vercel --prod
```

5. After deployment, verify the application is working correctly by:
   - Testing authentication
   - Creating and managing vehicles
   - Managing parts inventory
   - Using the interactive parts viewer
   - Testing the AI diagnostics feature

## Troubleshooting

If you encounter issues with the deployment:

1. Check the Vercel deployment logs
2. Verify environment variables are correctly set
3. Ensure Supabase project is properly configured
4. Check CORS settings in Supabase if authentication fails

## Updating the Deployment

To update the application after making changes:

1. Make your changes to the codebase
2. Build the web version:
```bash
flutter build web --release
```
3. Deploy the updated version:
```bash
vercel --prod
```
