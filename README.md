## Usage
```
# 必须已安装mysql, 具备root用户密码
# modify deploy.sh
	MYSQL_IP=10.108.172.201
	MYSQL_PORT=${MYSQL_PORT:-3306}
	MYSQL_ROOT_USER=root
	MYSQL_ROOT_PASSWORD=DP9bjfGg2J
sh deploy.sh (生成query.sh)
sh query.sh # 查看event
```
