#!
# 执行这个脚本就自动更新了
rm -rf node_modules && npm install --force
echo "Start ............."
hexo clean
hexo generate
hexo deploy
hexo g
git checkout raw
git reset --hard master
git push
git checkout master
echo "Finish ............."
