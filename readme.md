# 给 windows iso 镜像文件添加 virtio 驱动的脚本，以便在 kvm 虚拟化环境下安装 windows
## 使用方法
下载 windows iso 文件以及 virtio iso 文件
将两者解压放在一个目录  
把解压后的 windows iso 目录下的 sources 目录下的 install.wim 和 boot.wim 拷贝出来放到和本脚本同级的目录  
然后运行脚本（需打开管理员模式的 powershell ，并 `cd /path/to/file` 到当前目录，/path/to/file 替换为你脚本文件夹的绝对路径， 然后运行`.\Add-VirtIODrivers.ps1`按照提示输入信息即可  
待脚本运行成功后，使用软碟通（注册码网上有）（不能用压缩软件,否则会丢失 iso 元数据）等软件打开原 windows 的 iso 文件，将脚本同级目录的 install.wim 和 boot.wim 拖到打开的 iso 文件的 sources 目录，并点击替换按钮，替换完成后点击保存，生成新的 windows iso 文件，大功告成！
