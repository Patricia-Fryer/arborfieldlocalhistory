# Arborfield Local History

This repository has been initialized to hold the website for Arborfield Local History and to serve with GitHub Pages.

What I added for you:

- `README.md` (this file)
- `docs/index.html` — a placeholder GitHub Pages homepage so Pages can be enabled from the `main` branch using the `docs/` folder as the publishing source.

How to push your OneDrive site files into this repository (from your machine):

1. Open a terminal and go to your OneDrive-synced site folder, for example:

   cd "/path/to/OneDrive/YourSiteFolder"

2. If your site folder is NOT a git repo yet, run:

   git init
   git add .
   git commit -m "Initial commit: website from OneDrive"
   git branch -M main
   git remote add origin https://github.com/Patricia-Fryer/arborfieldlocalhistory.git
   git push -u origin main

3. If your site folder already has a `.git` history you want to keep, run:

   git remote remove origin || true
   git remote add origin https://github.com/Patricia-Fryer/arborfieldlocalhistory.git
   git branch -M main
   git push -u origin --all
   git push -u origin --tags

Notes:
- This repository is private as you requested. I did not change visibility.
- To publish the site with GitHub Pages using the `docs/` folder, go to: Settings → Pages → Source and select `main` branch and `/docs` folder, then save.
- If you prefer to publish from the repository root instead of `docs/`, tell me and I can add the placeholder to the root instead or create/update the Pages setting.

If you'd like, I can also:
- Enable GitHub Pages for you (I will need permission to modify repo settings), or
- Push the site files for you if you upload a zip of your OneDrive site here.

---
