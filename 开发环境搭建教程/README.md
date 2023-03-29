# 偷懒技巧
下面会介绍整个开发环境的配置，会编写系列代码，为了方便，我已经编写成shell脚本，就在目录[mini_os/代码/第一章/](https://github.com/luoyoutao/mini_os/tree/main/%E4%BB%A3%E7%A0%81/%E7%AC%AC%E4%B8%80%E7%AB%A0)，同时详细介绍了使用方法。    
# 从零开始搭建环境
1、VirtualBox的安装  
官网链接：https://www.virtualbox.org/wiki/Downloads  
![image](https://user-images.githubusercontent.com/40891397/190612279-e5c94e93-eab0-4f7f-b0ac-1b0338fdbd52.png)  
如上图，根据自己的电脑下载即可，该项目是在windows下开发，所以下载第一个。下载完成后，按照引导一步步安装即可。  

2、CentOS7的下载  
已经在上个目录的 所需工具中 给出了网盘链接，直接下载就行。  

3、在vbox中装centos7  
这里给出一个详细的教程链接（包括了初始化虚拟机、启动安装centos、设置网络）：https://zhuanlan.zhihu.com/p/60408219  
上面的教程是最小化安装，即安装的是无界面的，如果想要安装有界面的，需要在安装信息摘要页的软件的软件选择中根据需要安装其他功能（这样，后面就不用再安装增强功能了，因为后面编写操作系统会用到界面，还是得给centos升级才行）  

4、配置windows宿主机和VirtualBox中虚拟机的文件互传  
这里给出一个教程链接（共四种，该项目中选择了第3中，最方便）：https://blog.csdn.net/m0_60352504/article/details/119798970  
教程中开启ssh的命令无效，在centos中开启ssh命令为：sudo service sshd start，查看是否开始命令为：ps -e | grep sshd  

5、编译bochs源码  
把bochs-2.6.2tar.gz传到虚拟机centos中。这里编译，原书籍给出了教程，但是我经过尝试出现了各种问题，最后反复折腾，最终得到最简的步骤如下（虚拟机中按照顺序输入如下指令）：  
[root@localhost~]# yum install gcc-c++  
[root@localhost~]# yum install gtk2 gtk2-devel gtk2-devel-docs  
上面两条指令是安装必要的库。然后进入bochs-2.6.2tar.gz所在文件夹，输入解压指令，如下：  
[root@localhost~]# tar -zxvf bochs-2.6.2tar.gz  
解压后，进入解压的文件夹下，输入如下指令，需要注意的是，下面的指令中参数与参数之间有空格，第一个参数prefix是你想安装bochs到哪个绝对路径下，按照你自己的要求更改。  
[root@localhost~]# ./configure    --prefix=/your_path/bochs    --enable-debugger    --enable-disasm    --enable-iodebug  
--enable-x86-debugger    --with-x    --with-x11   LDFLAGS='-pthread'  
[root@localhost~]# make  
[root@localhost~]# make install  
到此就完全安装好bochs了。  

6、配置bochs  
配置bochs的相关信息，主要包括硬盘启动信息和内存等，已经放在了[mini_os/代码/第一章/](https://github.com/luoyoutao/mini_os/tree/main/%E4%BB%A3%E7%A0%81/%E7%AC%AC%E4%B8%80%E7%AB%A0)下的bochsrc.disk。这个文件最后需要放到安装好的bochs文件夹下。备后续开发使用。  

7、创建虚拟硬盘  
给bochs创建虚拟硬盘。bochs可以模拟硬件环境，包括硬盘。bochs给我们提供了创建虚拟硬盘的工具bin/bximage。我们先看下这个命令的帮助，如下所示：  
-fd 创建软盘  
-hd 创建硬盘  
-mode 创建硬盘的类型，有flat、sparse、growing三种  
-size 指创建多大的硬盘，以MB为单位  
-q 以静默模式创建，创建过程中不会和用户交互  
那么我们在bochs安装文件夹下执行如下命令：bin/bximage -hd -mode="flat" -szie=60 -q hd60M.img  

8、运行bochs  
由于运行中需要图像显示，而之前如果安装的是最小系统是没有图像的，那么这里需要安装图像界面，两条指令：  
[root@localhost~]# yum groupinstall "X Window System"  
[root@localhost~]# yum groupinstall "GNOME Desktop"  
安装后需要重启再进入图像模式，命令为：startx  
最后在bochs安装目录下运行命令：bin/bochs -f bochsrc.disk，然后回车，当出现<bochs:1>时，键入入c，出现如下图像就成功了：  
![image](https://user-images.githubusercontent.com/40891397/190629019-37466776-a0c9-468d-b36a-24c77716c071.png)
