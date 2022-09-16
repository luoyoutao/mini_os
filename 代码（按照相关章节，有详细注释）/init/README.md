# 先说重点
以上几个文件，compile_install_bochs.sh放在bochs源码的解压目录下，其余三个放在等待执行了compile_install_bochs.sh脚本后安装的、bochs目录下，bochsrc.disk不用执行，create_disk.sh只需要执行一次，run.sh会随着项目的进度不断完善它。下面详细说明。  
# 这几个文件的功能和使用说明
1、compile_install_bochs.sh  
是编译和安装bochs源码的shell脚本，需要在解压后的bochs目录下执行：./compile_install_bochs.sh。需要注意的是，里面的参数--prefix需要换成你的想要安装的目录，这里选择的是/home目录。  
2、create_disk.sh    
是创建虚拟硬盘的shell脚本，需要在安装好的bochs目录下执行：./create_disk.sh  
3、run.sh  
是bochs运行的shell脚本，需要在安装好的bochs目录下执行：./run.sh  
4、bochsrc.disk  
这个不用执行，这是虚拟硬盘的配置文件，启动bochs系统时会用到。  


