---
layout: post
title: "OpenStack QA"
description: "抽空整理的自己在使用OpenStack中的一些问题，分享出来，大家一起看看，如果有什么地方不对的还请指正。"
category: "OpenStack"
tags: [OpenStack, QA]
---
{% include JB/setup %}

##性能问题
###GRE性能问题
#####问题描述
采用Neutron的GRE模式，默认配置下，VM出网的性能极其低下，BUG列表：
https://bugs.launchpad.net/neutron/+bug/1252900

---

##Token过期数据问题
keystone把Token数据存放在数据库token表中，在使用过程中不会删除过期的Token数据，导致Token数据量异常。可参考https://bugs.launchpad.net/ubuntu/+source/keystone/+bug/1032633
{% highlight py %}
2013-12-05 19:13:11.732 2625 WARNING keystone.common.controller [-] RBAC: Invalid token
2013-12-05 19:13:11.732 2625 WARNING keystone.common.wsgi [-] Authorization failed. The request you have made requires authentication. from 192.168.1.165
{% endhighlight %}
###处理方式
http://www.sebastien-han.fr/blog/2012/12/12/cleanup-keystone-tokens/

---


##启动nova-compute报错
{% highlight py %}
\** (process:11739): WARNING **: Error connecting to bus: org.freedesktop.DBus.Error.FileNotFound: Failed to connect to socket /var/run/dbus/system_bus_socket: No such file or directory
process 11739: arguments to dbus_connection_get_data() were incorrect, assertion "connection != NULL" failed in file dbus-connection.c line 5804.
{% endhighlight %}
###处理方法
重启messagebus服务
{% highlight sh %}
[root@compute1 ~]# /etc/init.d/messagebus start
Starting system message bus:                               [  OK  ]
{% endhighlight %}
---

##启动ovs-agent出错
{% highlight py %}
2014-01-26 00:58:07.074 29610 TRACE neutron   File "/usr/lib/python2.6/site-packages/neutron/agent/linux/ip_lib.py", line 81, in _execute
2014-01-26 00:58:07.074 29610 TRACE neutron     root_helper=root_helper)
2014-01-26 00:58:07.074 29610 TRACE neutron   File "/usr/lib/python2.6/site-packages/neutron/agent/linux/utils.py", line 62, in execute
2014-01-26 00:58:07.074 29610 TRACE neutron     raise RuntimeError(m)
2014-01-26 00:58:07.074 29610 TRACE neutron RuntimeError:
2014-01-26 00:58:07.074 29610 TRACE neutron Command: ['ip', '-o', 'link', 'show', 'br-int']
2014-01-26 00:58:07.074 29610 TRACE neutron Exit code: 255
2014-01-26 00:58:07.074 29610 TRACE neutron Stdout: ''
2014-01-26 00:58:07.074 29610 TRACE neutron Stderr: 'Device "br-int" does not exist.\n'
2014-01-26 00:58:07.074 29610 TRACE neutron
{% endhighlight %}

---

###处理方式
增加br-int
{% highlight sh %}
[root@controller1 neutron]# ovs-vsctl add-br br-int
[root@controller1 neutron]# ovs-vsctl show
acb40cab-1fa0-48a0-a48c-56c89e1acfcd
   	Bridge br-int
       	Port br-int
           	Interface br-int
               	type: internal
   	ovs_version: "1.10.2"
[root@controller1 neutron]# ip -o link show br-int
5: br-int: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN \    link/ether 3e:d6:38:4e:28:43 brd ff:ff:ff:ff:ff:ff
{% endhighlight %}	
---
##qemu-kvm: failed to initialize spice server
spice配置问题，nova-compute节点的listen参数有问题！

---

##qemu-kvm error
{% highlight py %}
2014-03-13 18:01:11.312 12413 WARNING nova.virt.disk.api [req-4cb3d0ef-d70b-4383-a122-c070a62f757f 6965226966304bd5a3ae07587d5ef958 d2390e6dd4ce4b48866be0d3d1417c01] Ignoring error injecting data into image (Error mounting /share/instances/be363098-6749-42ea-84e0-824fdb1c8e59/disk with libguestfs (command failed: LC_ALL=C '/usr/libexec/qemu-kvm' -nographic -help
errno: File exists
{% endhighlight %}

###处理方式
{% highlight sh %}
[root@controller1 ~]# ln -s /usr/bin/qemu-kvm /usr/libexec/qemu-kvm
[root@controller1 ~]# ls -l /usr/libexec/qemu-kvm
lrwxrwxrwx 1 root root 17 Mar 27 17:15 /usr/libexec/qemu-kvm -> /usr/bin/qemu-kvm
{% endhighlight %}

##windows镜像注入问题
{% highlight sh %}
[root@compute2 /data/nova/instances/0071e60b-a0b6-41fa-b484-ede5448d87b9]#guestmount -a disk -i --ro /mnt/
guestmount: no operating system was found on this disk
{% endhighlight %}
未安装libguestfs-winsupport，需要安装libguestfs-winsupport。

###处理方法
{% highlight sh %}
[root@compute2 /root] yum install libguestfs-winsupport
{% endhighlight %}

---
##havana 2013.2.1 BUG
###UnboundLocalError: local variable 'instance_dir' when live migration

修改对应代码，在函数头加入network_name全局变量：nova/virt/libvirt/driver.py
{% highlight py %}
def pre_live_migration(self, context, instance, block_device_info,((Havana 2013.2.1))
#这个函数内增加instance_dir变量！
instance_dir = None
{% endhighlight %}
---
###UnboundLocalError: local variable 'network_name' in nova/virt/network/neutronv2/api.py,line 964
修改对应代码，在函数头加入network_name全局变量：
{% highlight py %}
def _nw_info_build_network(self, port, networks, subnets):
   	network_name = None(加入这个环境变量)
{% endhighlight %}
---
###快照无法显示在dashboard上
修改代码/usr/lib/python2.6/site-packages/nova/virt/libvirt/driver.py
{% highlight py %}
大概在1307行处
metadata = {'is_public': False,      这里的False改为True
{% endhighlight %}
---
##Libvirt error summary
###Failed to start domain错误
{% highlight sh %}	
[root@node1 ~]# virsh start vm01
error: Failed to start domain vm01
error: internal error process exited while connecting to monitor: Could not access KVM kernel module: No such file or directory
failed to initialize KVM: No such file or directory
No accelerator found!
{% endhighlight %}
####处理方法
上面的提示信息就是因为QEMU在初始化阶段因为无法找到kvm内核模块，确保内核支持KVM模块，硬件打开CPU VT技术。
{% highlight sh %}
	[root@node1 ~]# modprobe kvm   #载入kvm模块
	重启电脑，进入bios界面，设置advance（cpu）选项里面的virtualization标签为Enabled
	[root@node1 ~]# lsmod |grep kvm    #显示已载入的模块
	kvm_intel              54394  3
	kvm                   317536  1 kvm_intel
{% endhighlight %}
---
###虚拟机迁移错误	

####错误信息
{% highlight sh %}
[root@node1 ~]# virsh migrate --live 1 qemu+tcp://node2 --p2p --tunnelled --unsafe 
error: operation failed: Failed to connect to remote libvirt URI qemu+tcp://node2
{% endhighlight %}

####处理方法
在URI后面加上/system，‘system’相当于root用户的访问权限。

---
####错误信息
{% highlight sh %}
[root@node1 ~]# virsh migrate --live 2 qemu+tcp://node2/system --p2p --tunnelled
error: Unsafe migration: Migration may lead to data corruption if disks use cache != none
{% endhighlight %}
####处理方法
加上--unsafe参数进行迁移。

---
####错误信息
{% highlight sh %}
[root@node1 ~]# virsh migrate --live 2 qemu+tcp://192.168.0.121/system --p2p --tunnelled --unsafe 
error: Timed out during operation: cannot acquire state change lock 
{% endhighlight %}
####处理方法
启动虚拟机有时也会遇此错误,需要重启libvirtd进程。

---
####错误信息
{% highlight sh %}
[root@node1 ~]# virsh migrate 5 --live qemu+tcp://node2/system
error: Unable to read from monitor: Connection reset by peer
{% endhighlight %}
####处理方法
OpenStack nova.conf vncserver_listen的配置是否正确。

---
####错误信息
{% highlight sh %}
error: internal error Attempt to migrate guest to the same host 00020003-0004-0005-0006-000700080009
{% endhighlight %}
####处理方法
查看两个节点的system-uuid是否一样，如果一样需要修改libvirt的配置文件。可以通过如下的命令查看：
{% highlight sh %}
[root@controller1 ~]# dmidecode -s system-uuid
63897446-817B-0010-B604-089E01B33744
{% endhighlight %}
查看 /etc/libvirt/libvirtd.conf 中的host_uuid发现该行被注释，将该注释去掉，并需要对host_uuid的值进行修改！

在两台机器上分别用 cat /proc/sys/kernel/random/uuid的值来替换原来host_uuid的值！

---
###ssh-agent无法自启动
CentOS中ssh-agent无法自动启动，可以通过在**/etc/profile.d/ssh-agent.sh**，启动脚本的方式启动agent。
{% highlight sh %}
[root@test ~]# vim /etc/profile.d/ssh-agent.sh
#!/bin/sh
if [ -f ~/.agent.env ]; then
. ~/.agent.env >/dev/null
if ! kill -0 $SSH_AGENT_PID >/dev/null 2>&1; then
echo “Stale agent file found. Spawning new agent…”
eval `ssh-agent |tee ~/.agent.env`
ssh-add
fi
else
echo “Starting ssh-agent…”
eval `ssh-agent |tee ~/.agent.env`
ssh-add
fi
{% endhighlight %}

##nova-manage service list出现多余的主机名，服务状态为XXX，如果删除
通过清除nova数据库中的services表的binary字段对应的记录，（注意有外键约束，需要把services表和compute_nodes表的deleted字段都改为1)。
