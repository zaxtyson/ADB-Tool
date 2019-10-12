require "zfunc"
--全屏()
设置页面布局("layout")

设置标题栏("ADB-Tool",0xffffffff,0xff3F51B5)
--adb模式
adb.onClick=function(view)
  跳转页面("adb_start")
end

--fastboot模式
fastboot.onClick=function(view)

  -- 检查是否fastboot模式
  function is_fastboot()
    require "zfunc" --task线程使用独立命名空间，要重新导入zfunc
    local dev = sushell("fastboot devices")
    local dev = string.gsub(dev,"%s*fastboot%s*","")
    if dev ~= "" then return true,dev
    else return false
    end
  end

  local jz=加载框("检查设备连接状态...")
  显示(jz)

  -- 新线程检查连接状态，检查完毕使用匿名回调函数处理
  task(is_fastboot,function(x,dev)
    jz.dismiss()
    if x then
      下方提示("连接成功！")
      跳转页面("fastboot_function",{dev})
    else
      下方提示("连接失败")
    end
  end)
end

--创建必要目录
if not 存在("/.android") then sushell("mkdir /.android") end
if not 存在(家目录.."/HideAppList") then 创建目录(家目录.."/HideAppList") end
if not 存在(家目录.."/DisableAppList") then 创建目录(家目录.."/DisableAppList") end

--检查二进制文件是否安装
if not 存在("/system/bin/adb_tool_check") then

  function install(bin,qx)
    local mybin=家目录.."/adb/"..bin
    local sysbin="/system/bin/"..bin
    local bindir = sushell("which "..bin)
    bindir = string.gsub(bindir,"%s*","")
    if bindir ~= "" then sushell("rm -f "..bindir) end
    sushell("cp "..mybin.." "..sysbin)
    sushell("chmod "..qx.." "..sysbin)
  end

  local dhk = 对话框()
  设置对话框(dhk,"标题","安装二进制文件")
  设置对话框(dhk,"消息","嘿伙计，你好像没有安装adb和fastboot二进制文件(armv7版)。安装以后才能愉快的搞机啊！")
  设置对话框(dhk,"积极按钮","OK",function()
    下方提示("正在安装...")
    sushell("mount -o remount,rw /system")
    install("adb",744)
    install("fastboot",744)
    install("adb_tool_check",744)
  end)
  显示(dhk)
end