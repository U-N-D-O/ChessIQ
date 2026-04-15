# Firebase Cloud Functions Deployment Fix

## Issue Identified
**Root Cause:** IAM permissions issue - the compute service account (`806998148004-compute@developer.gserviceaccount.com`) lacks `Storage Object Viewer` and `Storage Admin` roles required to access the Cloud Storage bucket for staging function source code.

**Error Message:**
```
Build failed: Access to bucket gcf-sources-806998148004-us-central1 denied. 
You must grant Storage Object Viewer permission to 806998148004-compute@developer.gserviceaccount.com.
```

## Solution

### Step 1: Re-authenticate gcloud with Firebase
```bash
# Clear expired credentials
gcloud auth revoke --all

# Authenticate with gcloud
gcloud auth login
# Complete the browser-based OAuth flow

# Set the correct project
gcloud config set project chessiq-89b45
```

### Step 2: Grant Required IAM Permissions
```bash
# Grant Storage Object Viewer to compute service account
gcloud projects add-iam-policy-binding chessiq-89b45 \
  --member=serviceAccount:806998148004-compute@developer.gserviceaccount.com \
  --role=roles/storage.objectViewer

# Grant Storage Admin to compute service account (if object viewer isn't sufficient)
gcloud projects add-iam-policy-binding chessiq-89b45 \
  --member=serviceAccount:806998148004-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

# Also grant to Cloud Build service account
gcloud projects add-iam-policy-binding chessiq-89b45 \
  --member=serviceAccount:806998148004@cloudbuild.gserviceaccount.com \
  --role=roles/storage.objectViewer

# Grant Cloud Functions Developer role to App Engine default service account
gcloud projects add-iam-policy-binding chessiq-89b45 \
  --member=serviceAccount:chessiq-89b45@appspot.gserviceaccount.com \
  --role=roles/cloudfunctions.developer
```

### Step 3: Redeploy Cloud Functions
```bash
cd c:\src\ChessIQ\chessiq
firebase deploy --only functions
```

### Step 4: Verify Deployment
```bash
# Check function status
firebase functions:list --project chessiq-89b45

# Test endpoints
# - https://us-central1-chessiq-89b45.cloudfunctions.net/submitAcademyScore
# - https://us-central1-chessiq-89b45.cloudfunctions.net/checkHandleAvailability
# - https://us-central1-chessiq-89b45.cloudfunctions.net/getServerDate
```

## Alternative Solution via Google Cloud Console
If gcloud authentication continues to fail:

1. Open Google Cloud Console: https://console.cloud.google.com/
2. Select project: **chessiq-89b45**
3. Go to: **IAM & Admin** > **IAM**
4. Add these permissions to `806998148004-compute@developer.gserviceaccount.com`:
   - `roles/storage.objectViewer`
   - `roles/storage.admin`
5. Add these to `806998148004@cloudbuild.gserviceaccount.com`:
   - `roles/storage.objectViewer`
6. Retry deployment with Firebase CLI

## Status
- Functions deleted and ready for fresh deployment
- Firebase configuration verified (firebase.json, .firebaserc)
- TypeScript compilation successful
- IAM permissions need to be configured before redeployment
