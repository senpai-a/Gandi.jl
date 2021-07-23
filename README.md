# Gandi.jl #

肝帝

[演示视频](https://youtu.be/ZVQP1XPRwo4)

## 环境配置 ##

1. 安装Python 3
2. 安装依赖
	```
	pip install numpy opencv-python PyAutoGUI
	```
3. 安装Julia
4. 安装依赖
	- 进入Julia REPL
	- 输入']'进入包管理提示符，运行如下指令(可能需要全局代理)
	```
	add Images ImageMagick ImageFeatures PyCall Dates Statistics
	```

5. 配置PyCall，使用系统默认Python环境而不是Julia Conda环境
	- 按退格键回到Julia REPL
	- 运行 
	```
	ENV["PYTHON"]="python"
	```
	- 输入']'进入包管理提示符，运行如下指令
	```
	build PyCall
	```
