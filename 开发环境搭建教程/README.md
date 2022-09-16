# 从零开始搭建环境
1、VirtualBox的安装  
官网链接：https://www.virtualbox.org/wiki/Downloads  
![image](https://user-images.githubusercontent.com/40891397/190612279-e5c94e93-eab0-4f7f-b0ac-1b0338fdbd52.png)  
如上图，根据自己的电脑下载即可，该项目是在windows下开发，所以下载第一个。下载完成后，按照引导一步步安装即可。  

2、CentOS7的下载  
已经给出了网盘链接，直接下载就行。  

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
配置bochs的相关信息，主要包括硬盘启动信息和内存等，已经放在了[mini_os/]()中的bochsrc.disk。








