require "zfunc"
全屏()
设置页面布局("adb_start_lay")

-- 检查adb是否开启
function check_start()
  local r,state = sushell("ps | grep adbd")
  if state == 0 then
    设置标题栏("ADB已启动",0xffFFFFFF,0xff4CAF50)
    设置控件(choose_layout,"可见")
    return true
  else
    设置标题栏("ADB已关闭",0xffFFFFFF,0xff424242)
    设置控件(choose_layout,"不可见")
    return false
  end
end

-- 创建列表，选择设备
function choice_adb_dev()
  local dev_list = {} --设备名列表
  local id_list = {} -- 设备序列号列表

  local devices=sushell("adb devices -l") 
  devices=split(devices,"\n") -- 一行一个设备信息
  table.remove(devices,1) --第一行为adb提示信息，无用删掉
  for i,devinfo in pairs(devices) do
    if string.match(devinfo,"device") then --排除未授权的adb连接
      local devinfo=string.gmatch(devinfo,".-(.-)%s-device.-model:(.-) device.-")
      for id,dev in devinfo do
        table.insert(dev_list,dev)
        table.insert(id_list,id)
      end
    end
  end

  -- 列表点击事件,n为选中选项的序号，用它从id表里面取出id号 dev_name为选中的选项值(设备名)
  local function touch(n,dev_name)
    -- 把选中的设备id和设备名传给下一个界面
    跳转页面("adb_function",{id_list[n],dev_list[n]})
  end

  dhk = 对话框()
  设置对话框(dhk,"列表",dev_list,touch)
  设置对话框(dhk,"标题","可控制的设备")
  显示(dhk)
end

-- adb启动命令
start_cmd ="setprop service.adb.tcp.port 5555;start adbd"
stop_cmd = "setprop service.adb.tcp.port -1;stop adbd"
kill="adb kill-server"

-- 选择设备按钮
choose.onClick=function(view)
  choice_adb_dev()
end

-- 启动adb按钮
start_adb.onClick=function(view)
  下方提示("开启搞机模式...")
  sushell(start_cmd)
  check_start()
end

-- 重启adb按钮
restart_adb.onClick=function(view)
  下方提示("骚等...")
  sushell(stop_cmd)
  sushell(kill)
  sushell(start_cmd)
  check_start()
end

-- 关闭adb按钮
stop_adb.onClick=function(view)
  下方提示("关闭ADB...")
  sushell(stop_cmd)
  check_start()
end


--wifi连接
wifiadb.onClick=function(view)
  --输入对话框
  local t={
    LinearLayout;
    orientation="vertical";
    Focusable=true,
    FocusableInTouchMode=true,
    {
      EditText;
      hint="如:192.168.1.101:5555";
      layout_marginTop="5dp";
      layout_width="80%w";
      layout_gravity="center",
      id="edit";
    };
  }

  local dhk=对话框()
  设置对话框(dhk,"禁止返回")
  设置对话框(dhk,"标题","输入设备IP")
  设置对话框(dhk,"布局",t)
  设置对话框(dhk,"消极按钮","取消",nil)
  设置对话框(dhk,"积极按钮","连接▶",function(v)

    local dev=edit.Text
    local jzk=加载框("正在连接"..dev)

    local function connect(dev)
      require "zfunc"
      return sushell("adb connect "..dev) --这里返回状态码没用，连接错误也返回0
    end

    显示(jzk)
    task(connect,dev,function(r)
      jzk.dismiss()
      --如果结果包含unable说明连接失败
      if string.match(r,"unable") then 下方提示("连接失败") 
      else 下方提示("连接成功")
      end
    end)

  end)
  显示(dhk)

end

-- 窗口创建时
function onCreate()
  check_start()
  下方提示("启动adb之后再插入设备")
end