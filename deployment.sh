#!
# commit后执行这个脚本就自动更新了
echo "Start ............."
git push
rm -rf node_modules && npm install --force
hexo clean
hexo generate
hexo deploy
hexo g
git checkout master
git pull origin master
git checkout --orphan new
rm -rf .deploy_git
rm -rf node_modules
rm -rf public
rm -rf db.json
git add -A
git commit -m "更新"
git checkout master           
git reset --hard new  
git push -f origin master
git checkout write-here
git branch -D master
git branch -D new
echo "Finish ............."
