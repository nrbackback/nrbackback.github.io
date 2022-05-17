#!
# 执行这个脚本就自动更新了
rm -rf node_modules && npm install --force
echo "Start ............."
hexo clean
hexo generate
hexo deploy
hexo g
git checkout master
git pull origin master
git checkout --orphan new
git add -A
git commit -m "更新"
git branch -D dev
echo "Finish ............."
