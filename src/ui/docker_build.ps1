git show --format="%h" HEAD | select -First 1 > build_info.txt
git rev-parse --abbrev-ref HEAD >> build_info.txt

docker build -t $Env:USER_NAME/ui .