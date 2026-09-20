# Uncle Shodis Schools Portal — Cloud Sync Backend (Student Records)

This adds real cross-device data sync for the **Student Records** module of
the management portal, using Netlify Functions + Netlify Database
(a managed Postgres database). Everything else in the portal (staff, payroll,
attendance, billing, etc.) is untouched and still works exactly as before,
purely on this device's local storage.

## How it works
- `index.html` — your portal, with one addition: a "☁️ Cloud Sync" box on the
  Student Bio-Data page. Leave its Sync Key blank and nothing changes at all.
- `netlify/functions/students.js` — a small API that reads/writes student
  records to a real database, protected by a shared secret key.
- `netlify/database/migrations/` — the database table definition. Netlify
  runs this automatically when it builds the site — you never touch a
  database console directly.

## ⚠️ Why this needs one manual setup step
Unlike a plain HTML file, this project needs Netlify to **build** it (to
install the database package and run the migration). That requires linking
a GitHub repository to your Netlify site — a drag-and-drop upload alone
can't do this part. Here's the one-time setup:

### Step 1 — Put this project on GitHub (no command line needed)
1. Go to github.com and sign in (or create a free account).
2. Click the "+" in the top right → "New repository". Name it e.g.
   `shodis-schools-portal`. Keep it **Private** if you'd prefer. Click
   "Create repository".
3. On the new repo's page, click "uploading an existing file".
4. Drag this entire project folder's contents into the upload box (all of
   `index.html`, `netlify.toml`, `package.json`, `.gitignore`, and the
   `netlify` folder with everything inside it). Click "Commit changes".

### Step 2 — Link that repository to your existing Netlify site
1. Go to https://app.netlify.com/projects/shodis-schools-portal
2. Go to **Site configuration → Build & deploy → Continuous deployment**.
3. Click **Link repository** (or "Link site to Git") and choose the GitHub
   repo you just created. Netlify will detect `netlify.toml` automatically.
4. Trigger a deploy (Netlify usually starts one automatically after linking).
   Watch the deploy log — you should see it install `@netlify/database` and
   run the migration. When it finishes, your database is live.

### Step 3 — Set the shared Sync Key
1. In the same site settings, go to **Environment variables**.
2. Add a new variable: Key = `PORTAL_API_KEY`, Value = a password of your
   choosing (e.g. a long random phrase — this is what protects your student
   data from strangers, so keep it private and only share it with staff who
   need it).
3. Re-deploy the site once more so the new environment variable takes effect
   (Deploys tab → "Trigger deploy" → "Deploy site").

### Step 4 — Turn sync on, on each device
1. Open the live portal, log in, go to **Student Bio-Data**.
2. In the "☁️ Cloud Sync" box, paste the same Sync Key from Step 3, click
   **Save Key**. It syncs automatically from then on, every time a student
   record is saved, and pulls the latest on every page load.
3. Repeat on every device/computer that should share the same student data.

## What this does NOT yet do (by design — see the chat for why)
- Only **Student Records** sync. Staff, payroll, attendance, billing, and
  loans still save to this device's local storage only, same as before.
- The Sync Key is a single shared secret, not individual staff logins on the
  server side (the portal's own multi-user login still gates the *app*, this
  just gates the *data API*). A fuller version would give each staff member
  their own server-recognized account.
- If you'd like more modules (e.g. Staff Records, Attendance) synced the same
  way, that follows the same pattern used here for Students — ask and it can
  be added module by module.

## Local testing (optional, for anyone comfortable with Node.js)
```
npm install
netlify dev
```
This requires the Netlify CLI (`npm install -g netlify-cli`) and running
`netlify link` first to connect to the `shodis-schools-portal` site.
