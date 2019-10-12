require "zfunc"
全屏()
设置页面布局("adb_function_lay")

-- 接受adb_main传过来的参数:设备id 设备名
dev_id,dev_name = ...
设置标题栏("ADB : " .. dev_name.." ["..dev_id.."]",0xffFFFFFF,0xff8E24AA)


--指定设备运行adb命令
function adb(cmd)
  return sushell("adb -s "..dev_id.." "..cmd)
end

function taskshell(cmd)
  require "zfunc"
  return sushell(cmd)
end

-- 重启按钮
reboot.onClick=function(view)
  local dhk = 对话框()
  设置对话框(dhk,"消息","重启"..dev_name)
  设置对话框(dhk,"积极按钮","重启",function() adb("reboot") end)
  设置对话框(dhk,"中立按钮","手滑点错了")
  显示(dhk)
end


-- 重启到recovery按钮
recovery.onClick=function(view)
  local dhk = 对话框()
  设置对话框(dhk,"标题","重启"..dev_name.."到recovery模式")
  设置对话框(dhk,"积极按钮","重启",function() adb("reboot recovery") end)
  设置对话框(dhk,"中立按钮","手滑点错了")
  显示(dhk)
end



-- 重启到fastboot按钮
fastboot.onClick=function(view)
  local dhk = 对话框()
  设置对话框(dhk,"标题","重启"..dev_name.."到bootloader模式")
  设置对话框(dhk,"积极按钮","重启",function()
    adb("reboot bootloader")
    延时(1)
    activity.finish()
    跳转页面("main")
    下方提示("选择\"fastboot模式\"")
  end)
  设置对话框(dhk,"中立按钮","手滑点错了")
  显示(dhk)
end




--上传文件
push.onClick=function(view)
  local function upload(file)
    --输入对话框
    local t={
      LinearLayout;
      orientation="vertical";
      Focusable=true,
      FocusableInTouchMode=true,
      {
        EditText;
        hint="如:/sdcard";
        layout_marginTop="5dp";
        layout_width="80%w";
        layout_gravity="center",
        id="edit";
      };
    }

    dhk=对话框()
    设置对话框(dhk,"禁止返回")
    设置对话框(dhk,"标题","输入远程保存路径")
    设置对话框(dhk,"布局",t)
    设置对话框(dhk,"消极按钮","取消",nil)
    设置对话框(dhk,"积极按钮","上传▶",function(v)

      local remote=edit.Text
      if remote == "" then remote="/sdcard" end
      local jzk=加载框("上传:"..file.."\n路径:"..remote)
      显示(jzk)

      local function upload_finish(r)
        jzk.dismiss()
        local dhk2=对话框()
        设置对话框(dhk2,"标题","上传完成")
        设置对话框(dhk2,"消息",r)
        设置对话框(dhk2,"积极按钮","OK",nil)
        显示(dhk2)
      end

      if string.sub(remote,-1,-1) ~= "/" then remote=remote.."/" end --标准化路径格式
      local cmd=string.format([[adb -s "%s" push "%s" "%s"]],dev_id,file,remote)
      task(taskshell,cmd,upload_finish)

    end)--设置对话框
    显示(dhk)
  end --upload
  选择文件("/",upload)
end




--下载文件
pull.onClick=function(view)

  --shell远程文件浏览器
  function opendir(path)

    --分析ls -l的数据，判断是否目录
    local function analyze(tb)
      list={}
      for i,v in pairs(tb) do

        local tp = string.sub(v,1,1)
        local name = (string.gsub(v,".*%d%d:%d%d%s(.-)%s","%1"))

        --如果是目录，在名字前面加符号
        if tp == "d" then table.insert(list,"������ "..name)
          --如果是文件，直接加入列表
        elseif tp == "-" then table.insert(list,name)
        end --if

      end --for
      table.sort(list)
      table.insert(list,1,"������������������") --返回上级选项
      return list
    end --analyze(tb)

    --路径标准化
    path=string.gsub(path,"//","/")
    path=string.gsub(path,"������ ","")
    if string.sub(path,-1,-1) ~= "/" then path=path.."/" end

    local file_list=adb("shell ls -al "..path) --ls -l获取文件列表
    file_list=split(file_list,"\n")
    table.remove(file_list) --去除最后一行空白

    local file_list_dhk=对话框()
    设置对话框(file_list_dhk,"标题","下载文件")
    设置对话框(file_list_dhk,"列表",analyze(file_list),function(k,v)

      --下载文件用的函数
      local function downfile(save_dir)
        
        local jzk=加载框("下载:"..v.."\n路径:"..save_dir)
        显示(jzk)



        local function down_finish(r)
          jzk.dismiss()
          local dhk2=对话框()
          设置对话框(dhk2,"标题","复制完成")
          设置对话框(dhk2,"消息",r)
          设置对话框(dhk2,"积极按钮","OK",nil)
          显示(dhk2)
        end

        local cmd=string.format([[adb -s "%s" pull "%s" "%s"]],dev_id,path..v,save_dir)
        task(taskshell,cmd,down_finish)

      end --downfile(save_dir)


      --点击"返回上级"
      if string.match(v,"������") then
        local updir=(string.gsub(path,"(.*/).-/$","%1"))
        opendir(updir)

        --点击目录
      elseif string.match(v,"������") then
        local ndir=path..(string.gsub(v,"������ (.*)%s$","%1"))
        opendir(ndir)

        --点击其它文件
      else
        --选择保存路径
        local t={
          LinearLayout;
          orientation="vertical";
          Focusable=true,
          FocusableInTouchMode=true,
          {
            EditText;
            hint="如:/sdcard";
            layout_marginTop="5dp";
            layout_width="80%w";
            layout_gravity="center",
            id="edit";
          };
        }

        local dhk3=对话框()
        设置对话框(dhk3,"禁止返回")
        设置对话框(dhk3,"标题","输入下载路径")
        设置对话框(dhk3,"布局",t)
        设置对话框(dhk3,"消极按钮","取消",nil)
        设置对话框(dhk3,"积极按钮","下载▶",function(v)
          local save_dir=edit.Text
          if save_dir == "" then save_dir="/sdcard" end
          if string.sub(save_dir,-1,-1) ~= "/" then save_dir=save_dir.."/" end --标准化路径格式
          downfile(save_dir)
        end)
        显示(dhk3)

      end --情况判断结束

    end)--文件列表点击事件结束

    显示(file_list_dhk)
  end --opendir(path)

  opendir("/")

end --pull结束





--安装app
install.onClick=function(view)
  --安装apk，接收apk路径
  local function inapp(app)
    --拒绝安装非apk文件
    if not string.match(app,".apk") then 
      下方提示("请选择一个apk文件")
      return 1
    end
    --从路径中截取apk名称
    local app_name=string.match(app,".*/(.-%.apk)")
    local dhk=对话框()
    设置对话框(dhk,"标题","确认上传并安装"..app_name.."？")
    设置对话框(dhk,"积极按钮","安装",function()

      local jzk=加载框("正在安装"..app_name)
      显示(jzk)

      local function install_app(cmd)
        require "zfunc"
        return sushell(cmd)
      end

      function install_finish(r)
        jzk.dismiss()
        local dhk2=对话框()
        设置对话框(dhk2,"标题","安装结果")
        设置对话框(dhk2,"消息",r)
        设置对话框(dhk2,"积极按钮","OK",nil)
        显示(dhk2)
      end
      local cmd="adb -s "..dev_id.." install -r "..app
      task(install_app,cmd,install_finish)

    end)
    设置对话框(dhk,"中立按钮","取消",nil)
    显示(dhk)
  end
  选择文件("/sdcard",inapp)
end




--arg:-s列出系统包名列表 -3列出第三方包 不填就是全部
function ls_pkg(arg)
  --查询apk列表
  if arg == nil then arg="" end
  local pkgs=adb("shell pm list packages "..arg.."")
  pkgs=string.gsub(pkgs,"package:(.-)%s","%1")
  pkgs=split(pkgs,"\n")
  table.remove(pkgs) --去除最后一个空白
  table.sort(pkgs)
  return pkgs
end




--卸载app
uninstall.onClick=function(view)
  local pkg_list = ls_pkg("-3")
  --选择app包名的对话框
  local dhk=对话框()
  设置对话框(dhk,"标题","卸载软件")
  设置对话框(dhk,"列表",pkg_list,function(k,pkg)
    --列表点击事件
    local yn=对话框()
    设置对话框(yn,"消息","确认卸载"..pkg.."？")
    设置对话框(yn,"中立按钮","取消",nil)
    设置对话框(yn,"积极按钮","确认",function()
      --卸载安装包
      local r=adb("uninstall "..pkg)
      local dhk1=对话框()
      设置对话框(dhk1,"标题","正在卸载...")
      设置对话框(dhk1,"消息",r)
      设置对话框(dhk1,"积极按钮","OK",nil)
      显示(dhk1)
    end)
    显示(yn)
  end)
  显示(dhk)
end






--隐藏app
hide.onClick=function(view)
  local pkg_list=ls_pkg()
  local dhk=对话框()
  设置对话框(dhk,"标题","隐藏软件")
  设置对话框(dhk,"列表",pkg_list,function(k,pkg)
    --列表点击事件
    local yn=对话框()
    设置对话框(yn,"消息","确认隐藏"..pkg.."？")
    设置对话框(yn,"中立按钮","取消",nil)
    设置对话框(yn,"积极按钮","确认",function()
      --隐藏安装包
      local r=adb("shell pm hide "..pkg)
      --保存隐藏app的包名，用于后续恢复
      local hide_app=家目录.."/HideAppList/"..pkg 
      if not 存在文件(hide_app) then 创建文件(hide_app) end 

      local dhk1=对话框()
      设置对话框(dhk1,"标题","正在隐藏...")
      设置对话框(dhk1,"消息",r)
      设置对话框(dhk1,"积极按钮","OK",nil)
      显示(dhk1)
    end)
    显示(yn)
  end)
  显示(dhk)
end






--取消隐藏app
unhide.onClick=function(view)
  local hide_app=家目录.."/HideAppList/"
  local file_list=获取文件列表(hide_app)
  local hide_list ={}
  for i,pkg in pairs(file_list) do
    hide_list[i]=获取文件名(tostring(pkg))
  end
  local dhk=对话框()
  设置对话框(dhk,"标题","取消隐藏")
  设置对话框(dhk,"列表",hide_list,function(k,pkg)
    --列表点击事件
    local yn=对话框()
    设置对话框(yn,"消息","确认恢复"..pkg.."？")
    设置对话框(yn,"中立按钮","取消",nil)
    设置对话框(yn,"积极按钮","确认",function()
      --取消隐藏安装包
      local r=adb("shell pm unhide "..pkg)
      --删除备份包名文件
      删除(hide_app.."/"..pkg)
      local dhk1=对话框()
      设置对话框(dhk1,"标题","正在取消隐藏...")
      设置对话框(dhk1,"消息",r)
      设置对话框(dhk1,"积极按钮","OK",nil)
      显示(dhk1)
    end)
    显示(yn)
  end)
  显示(dhk)
end






--冻结app
disable.onClick=function(view)
  local pkg_list=ls_pkg("-3") --列出系统app
  local dhk=对话框()
  设置对话框(dhk,"标题","冻结软件")
  设置对话框(dhk,"列表",pkg_list,function(k,pkg)
    --列表点击事件
    local yn=对话框()
    设置对话框(yn,"消息","确认冻结"..pkg.."？")
    设置对话框(yn,"中立按钮","取消",nil)
    设置对话框(yn,"积极按钮","确认",function()
      --隐藏安装包
      local r=adb("shell pm disable "..pkg)
      --保存冻结app的包名，用于后续恢复
      local disable_app=家目录.."/DisableAppList/"..pkg 
      if not 存在文件(disable_app) then 创建文件(disable_app) end 
      local dhk1=对话框()
      设置对话框(dhk1,"标题","正在冻结...")
      设置对话框(dhk1,"消息",r)
      设置对话框(dhk1,"积极按钮","OK",nil)
      显示(dhk1)
    end)
    显示(yn)
  end)
  显示(dhk)
end





--取消冻结app
enable.onClick=function(view)
  local disable_app=家目录.."/DisableAppList/"
  local file_list=获取文件列表(disable_app)
  local disable_list ={}
  for i,pkg in pairs(file_list) do
    disable_list[i]=获取文件名(tostring(pkg))
  end
  local dhk=对话框()
  设置对话框(dhk,"标题","取消冻结")
  设置对话框(dhk,"列表",disable_list,function(k,pkg)
    --列表点击事件
    local yn=对话框()
    设置对话框(yn,"消息","确认恢复"..pkg.."？")
    设置对话框(yn,"中立按钮","取消",nil)
    设置对话框(yn,"积极按钮","确认",function()
      --取消隐藏安装包
      local r=adb("shell pm enable "..pkg)
      --删除备份包名文件
      删除(disable_app.."/"..pkg)
      local dhk1=对话框()
      设置对话框(dhk1,"标题","正在取消隐藏...")
      设置对话框(dhk1,"消息",r)
      设置对话框(dhk1,"积极按钮","OK",nil)
      显示(dhk1)
    end)
    显示(yn)
  end)
  显示(dhk)
end