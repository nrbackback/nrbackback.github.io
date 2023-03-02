#!
# commit后执行这个脚本就自动更新了
# githhub上的博客需要同步到笔记（优先）或者本地。不要提交敏感内容
echo "Start ............."
git push
rm -rf node_modules && npm install --force
hexo clean
hexo generate
hexo deploy
hexo g
git fetch origin -a
git checkout remotes/origin/master
git checkout -b master
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
# hexo n test  新建名为  test 的文章，参考 https://zhuanlan.zhihu.com/p/132823826
