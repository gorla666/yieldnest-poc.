# one‑liner to drop common junk
echo -e "out/\ncache/\n.env\ndeploy.json\n*.DS_Store" > .gitignore

git add .gitignore LICENSE README.md
git commit -m "chore: housekeeping files"
