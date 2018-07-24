zfunc = {}
require "import"
import "android.view.WindowManager"
import "java.lang.Thread"
import "java.net.URLDecoder"
import "android.net.Uri"
import "android.content.Intent"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.BitmapDrawable"
import "com.androlua.LuaUtil"
import "java.util.Calendar"
import "android.text.format.Formatter"
import "android.content.Context"
import "android.text.SpannableString"
import "android.text.style.ForegroundColorSpan"
import "android.text.Spannable"
import "android.app.ActionBar$TabListener"


家目录=activity.getLuaDir()


-- ============ WiFi相关 ================

function 获取wifi(x)
  local wifi = activity.Context.getSystemService(Context.WIFI_SERVICE)
  local info = wifi.getConnectionInfo()
  local dns_info = tostring(wifi.getDhcpInfo())
  local status={"关闭中","已关闭","开启中","已开启","未知状态"}

  info_result = {
    id=info.getNetworkId(),
    名称=info.getSSID(),
    频率=info.getFrequency(), --单位Mhz
    是否隐藏=info.getHiddenSSID(),
    连接速度=info.getLinkSpeed(), --单位Mbps
    本机mac=info.getMacAddress(),
    路由mac=info.getBSSID(),
    信号强度=tostring(info.getRssi()), --单位dBm
    启用状态=tostring(status[wifi.getWifiState()+1]),
    是否开启=wifi.isWifiEnabled(),
    本机ip=string.match(dns_info,"ipaddr (.-) gateway"),
    网关ip=string.match(dns_info,"gateway (.-) netmask"),
    子网掩码=string.match(dns_info,"netmask (.-) dns1"),
    dns1=string.match(dns_info,"dns1 (.-) dns2"),
    dns2=string.match(dns_info,"dns2 (.-) DHCP"),
    dhcp=string.match(dns_info,"DHCP server (.-) lease"),
    租约=string.match(dns_info,"lease (.-) seconds").."秒",
  }

  return info_result[x]
end

function 设置wifi(x)
  local wifi = activity.Context.getSystemService(Context.WIFI_SERVICE)
  if x == "打开" then return wifi.setWifiEnabled(true)
  elseif x == "关闭" then return wifi.setWifiEnabled(false)
  elseif x == "断开连接" then return wifi.disconnect()
  elseif x == "重新连接" then return wifi.reassociate()
  elseif x == "忘记密码" then return wifi.removeNetwork(获取wifi("id")) end
end

-- =============== 文件I/O相关 ===============

-- 文件处理函数 路径最后面的/会被忽略 使用绝对路径
function 存在(path)return File(path).exists()end

function 存在文件(file_path)return File(file_path).isFile() end

function 存在目录(dir_path)return File(dir_path).isDirectory() end

--路径不存在就会自动递归创建
function 创建文件(file_path)
  File(tostring(File(tostring(file_path)).getParentFile())).mkdirs()
  return File(file_path).createNewFile()
end

-- 创建文件夹时自动递归创建路径
function 创建目录(dir_path)return File(dir_path).mkdirs()end

function 获取文件名(file_path)return File(file_path).getName() end

function 获取上级路径(path)return File(path).getParentFile() end

function 获取文件字节数(file_path)return File(file_path).length() end

-- 单位：KB MB GB
function 获取文件大小(path)
  local size=File(tostring(path)).length()
  local sizes=Formatter.formatFileSize(activity, size)
  return sizes
end

-- 获取该路径下文件夹和文件的名字，包括以.开头的隐藏文件
function 获取文件列表(dir_path)return luajava.astable(File(dir_path).listFiles()) end

-- 获取文件或者文件夹的最后修改时间，文件不存在时返回 1970年1月1日 08:00:00
function 获取修改时间(path)
  local f = File(path)
  local cal = Calendar.getInstance()
  local time = f.lastModified()
  cal.setTimeInMillis(time)
  return cal.getTime().toLocaleString()
end

-- 该路径可以不存在
function 获取mime类型(name)
  import "android.webkit.MimeTypeMap"
  ExtensionName=tostring(name):match("%.(.+)")
  Mime=MimeTypeMap.getSingleton().getMimeTypeFromExtension(ExtensionName)
  return tostring(Mime)
end

-- 两个参数都使用绝对路径，带上文件名
function 移动(old_dir,new_dir)return File(old_dir).renameTo(File(new_dir))end

-- 会自动创建路径
function 复制(from_path,to_path)return LuaUtil.copyDir(from_path,to_path)end

-- 可以删除文件和文件夹
function 删除(path)return LuaUtil.rmDir(File(path))end

-- 会自动创建不存在的文件夹，然后创建文件
function 写入(file_path,txt)
  创建文件(file_path)
  return io.open(file_path,"w"):write(txt):close()
end

--给的文件路径一定要存在，不会自动创建不存在的文件夹
function 追加写入(file_path,txt)
  io.open(file_path,"a+"):write(txt):close()
end

function 读取(file_path)
  return io.open(file_path):read("*a")
end

-- Toast 提示
function 显示(id) id.show() end
function 提示(msg,time) return Toast.makeText(activity,msg,time) end
function 设置提示布局(obj,layout) obj.setView(loadlayout(layout))end
--function 设置提示内容(obj,txt)obj.setText(txt)end
-- 参数:提示对象，Gravity常量，x轴偏移量，y轴偏移量
-- 详细内容 https://developer.android.google.cn/reference/android/view/Gravity
function 设置提示位置(obj,i,xOffset,yOffset)
  local tb={上=Gravity.TOP,下=Gravity.BOTTOM,中=Gravity.CENTER,左=Gravity.LEFT,右=Gravity.RIGHT}
  obj.setGravity(tb[i],xOffset,yOffset)
end

function 下方提示(msg)
  local tip = 提示(msg,3)
  --设置提示内容(tip,msg)
  设置提示位置(tip,"下",0,20)
  显示(tip)
end

-- AlertDialog对话框
function 对话框()return AlertDialog.Builder(activity)end

function 设置对话框(obj,x,y,func)
  if     x == "标题"  then obj.setTitle(y) -- y是文本
  elseif x == "禁止返回" then obj.setCancelable(false)
  elseif x == "布局" then obj.setView(loadlayout(y))
  elseif x == "消息" then obj.setMessage(y)
  elseif x == "图标" then obj.setIcon(BitmapDrawable(loadbitmap(y))) --y是图片路径，相当于布局表里面的src的值,如"image/a.jpg"
  elseif x == "中立按钮" then obj.setNeutralButton(y,{onClick=func})
  elseif x == "消极按钮" then obj.setNegativeButton(y,{onClick=func})
  elseif x == "积极按钮" then obj.setPositiveButton(y,{onClick=func})
  elseif x == "列表" then obj.setItems(y,{onClick=function(a,num) func(num+1,y[num+1]) end}) --接受一个函数func(点击选项序号,选项值)
  elseif x == "单选框" then obj.setSingleChoiceItems(y,-1,{onClick=function(a,num) 选择结果=num+1 end})
    -- y是选项列表 -1表示默认不选择任何一个选项 0表示默认勾选第一个选项，以此类推
    -- 全局变量table"选择结果"保存选择结果，在主程序里面直接处理即可
  elseif x == "复选框" then
    选择结果={}
    obj.setMultiChoiceItems(y,nil,{onClick=
      function(dia,which,state)
        if state == true then
          table.insert(选择结果,which+1)
        else table.remove(选择结果,which+1)
        end
      end})
  end
end


-- ============== 用户界面相关 ================
function 沉浸式状态栏()activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)end

function 加载图片(img_path) return BitmapDrawable(loadbitmap(img_path))end

function 设置页面布局(lay)activity.setContentView(loadlayout(lay))end

-- lua_path为新界面的名字(xxx.lua就写xxx，不写后缀.lua)
-- args为要传递的参数表table 在新界面通过function main(...) 来得到穿过来的参数
function 跳转页面(lua_path,args)activity.newActivity(lua_path,args)end

function 设置控件(id,state)
  if state == "可见" then id.setVisibility(View.VISIBLE)
  elseif state == "不可见" then id.setVisibility(View.INVISIBLE)
  elseif state == "隐藏" then id.setVisibility(View.GONE) end
end


-- =========== ActionBar ======================

function 隐藏标题栏() activity.ActionBar.hide() end

-- logo为图标路径
function 设置标题栏图标(logo)
  activity.ActionBar.setDisplayShowHomeEnabled(true)
  activity.ActionBar.setDisplayUseLogoEnabled(true)
  activity.ActionBar.setLogo(加载图片(logo))
end

-- layout为布局文件 例:加载test.aly布局文件 > 设置标题布局("test")
function 设置标题栏布局(layout)
  activity.ActionBar.setCustomView(loadlayout(layout))
end

-- 设置标题(标题文本,字体颜色,背景颜色)
function 设置标题栏(txt,color,bgcolor)
  local sp = SpannableString(txt)
  sp.setSpan(ForegroundColorSpan(color),0,#sp,Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
  activity.ActionBar.setTitle(sp)
  activity.ActionBar.setBackgroundDrawable(ColorDrawable(bgcolor))
end

-- ActionBar 右上角菜单
function 创建菜单(tb)
  function onCreateOptionsMenu(menu)
    for k,v in pairs(tb) do
      menu.add(Menu.NONE,k,k,v)
    end
  end
end

-- 设置标题返回键(图标路径,菜单函数表)
-- 如果设置了菜单，此函数应该在"设置菜单点击事件()"之后调用
function 设置标题返回键(icon,func_tb)
  activity.ActionBar.setDisplayHomeAsUpEnabled(true)
  if icon then activity.ActionBar.setHomeAsUpIndicator(加载图片(icon)) end
  if func_tb == nil then func_tb = {} end
  title_back=android.R.id.home
  func_tb["title_back"]=function()this.finish()end --该触发事件可自定义修改
  设置菜单点击事件(func_tb)
end


--[[ 用法:
fuck=9465454
tb={func1,func2,func3,fuck=func4}
菜单点击事件(tb)
说明:
tb中的函数与菜单的选项按顺序一一对应，tb为全局变量
id=func4这种写法是为了防止超级长的id导致数组下标越界
tb里面的fuck只是字符串，先要把真正的id号赋值给一个与它同名的全局变量
func1,func2这些函数的第一个参数为你点击的选项(item对象)
]]
function 设置菜单点击事件(tb)
  function onOptionsItemSelected(item)
    for k,v in pairs(tb) do
      if item.getItemId() == k then tb[k](item)
      elseif item.getItemId() == _G[k] then tb[k](item)
      end
    end
  end
end


-- ================ 导航栏相关 ===============

--导航栏 谷歌官方不推荐使用
function 导航栏()
  activity.ActionBar.setNavigationMode(2)
  return activity.ActionBar
end

-- 添加导航栏选项(导航栏对象,标题,点击事件处理函数)
function 添加导航栏选项(obj,txt,func)
  local tab = obj.newTab().setText(txt).setTabListener(TabListener({onTabSelected=func}))
  obj.addTab(tab)
end

function 选中导航栏选项(obj,int)obj.setSelectedNavigationItem(int-1)end

function 删除导航栏选项(obj,int)obj.removeTabAt(int-1)end

function 设置导航栏颜色(obj,bgcolor)obj.setStackedBackgroundDrawable(ColorDrawable(bgcolor))end


-- =============== 其它函数 =============

function 写入剪贴板(txt) return activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(txt) end

function 读取剪贴板() return activity.getSystemService(Context.CLIPBOARD_SERVICE).getText() end

--获取运营商名称需添加权限  READ_PHONE_STATE
function 获取运营商名称() return this.getSystemService(Context.TELEPHONY_SERVICE).getNetworkOperatorName() end

--执行shell命令
function shell(cmd)
  local cmd = cmd..[[ 2>&1;echo "#code#$?"]] --获取标准错误输出
  local p=io.popen(string.format('%s',cmd))
  local s=p:read("*a")
  p:close()
  local r=string.split(s,"#code#")
  result=(string.gsub(r[1],"\n\n",""))
  code=(string.gsub(r[2],"\n",""))
  return result,tonumber(code) --返回结果和状态码
end

-- root shell
function sushell(cmd)
  local cmd=[[su -c ']]..cmd..[[']]
  return shell(cmd)
end

-- 计时器(间隔时间,间隔次数[,每个间隔执行的函数,结束时执行的函数]) 时间单位:秒 计时器不会阻塞进程
function 计时器(period,num,...)
  local perfunc,endfunc = ...
  local a=0
  local t=Ticker()
  t.Period=period*1000
  t.onTick=function()
    a=a+1
    if perfunc then perfunc() end
    if a==num then
      t.stop()
      if endfunc then endfunc() end
    end
  end
  t.start()
end

-- 会阻塞进程
function 延时(time)
  Thread.sleep(time*1000)
end



--加群
function 加qq群(qq)
  url="mqqapi://card/show_pslcard?src_type=internal&version=1&uin="..tostring(qq).."&card_type=group&source=qrcode"
  activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
end

--QQ聊天
function 加qq(qq)
  url="mqqwpa://im/chat?chat_type=wpa&uin="..tostring(qq)
  activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
end

--加载框(信息)
function 加载框(msg)
  return ProgressDialog.show(activity,nil,msg)
  --dl.show()
  --计时器(1,time,nil,dl.dismiss)
end

--打开浏览器访问url
function 访问(url)
  viewIntent = Intent("android.intent.action.VIEW",Uri.parse(url))
  activity.startActivity(viewIntent)
end

--安装软件
function 安装(apk_path)
  intent = Intent(Intent.ACTION_VIEW)
  intent.setDataAndType(Uri.parse("file://"..apk_path), "application/vnd.android.package-archive") 
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  activity.startActivity(intent)
end

--卸载软件
function 卸载(package_name)
  uri = Uri.parse("package:"..package_name)
  intent = Intent(Intent.ACTION_DELETE,uri)
  activity.startActivity(intent)
end

--播放mp3
function 播放mp3(mp3_path)
  intent = Intent(Intent.ACTION_VIEW)
  uri = Uri.parse("file://"..mp3_path)
  intent.setDataAndType(uri, "audio/mp3")
  this.startActivity(intent)
end

function 播放mp4(mp4_path)
  intent = Intent(Intent.ACTION_VIEW)
  uri = Uri.parse("file://"..mp4_path) 
  intent.setDataAndType(uri, "video/mp4")
  activity.startActivity(intent)
end

--发送短信
function 发短信(num,msg)
  SmsManager.getDefault().sendTextMessage(tostring(num), nil, tostring(msg), nil, nil)
end

function 全屏()
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
end

--分割字符
function split(s,sp)
  local res = {} 
  local temp = s
  local len = 0
  while true do
    len = string.find(temp,sp)
    if len ~= nil then
      local result = string.sub(temp,1, len-1)
      temp = string.sub(temp, len+1)
      table.insert(res,result)
    else
      table.insert(res, temp)
      break
    end
  end
  return res
end









function 获取app信息(包名)
  import "android.content.pm.PackageManager"
  local pm = activity.getPackageManager();
  local 图标 = pm.getApplicationInfo(tostring(包名),0)
  local 图标 = 图标.loadIcon(pm)
  local pkg = activity.getPackageManager().getPackageInfo(包名, 0); 
  local 应用名称 = pkg.applicationInfo.loadLabel(activity.getPackageManager())
  local 版本号 = activity.getPackageManager().getPackageInfo(包名, 0).versionName
  local 最后更新时间 = activity.getPackageManager().getPackageInfo(包名, 0).lastUpdateTime
  local cal = Calendar.getInstance();
  cal.setTimeInMillis(最后更新时间); 
  local 最后更新时间 = cal.getTime().toLocaleString()
  return {应用名称,包名,版本号,最后更新时间,图标}
end

--简易文件选择器，func(file)为回调函数:
function 选择文件(path,func)

  local function analyze(file_list)
    list={}
    for i,v in pairs(file_list) do
      local name=v.getName()
      if v.isDirectory() then name="������ "..name end --目录前面加图标
      table.insert(list,name)
    end

    table.sort(list) --排序
    table.insert(list,1,"������������������") --返回上一级图标
    return list
  end

  --标准化路径格式
  path=string.gsub(path,"//","/")
  if string.sub(path,-1,-1) ~= "/" then path=path.."/" end

  -- 获取文件列表
  local file_list=luajava.astable(File(path).listFiles())

  local dhk=对话框()
  设置对话框(dhk,"标题","选择文件")
  设置对话框(dhk,"列表",analyze(file_list),function(k,v)
    --如果点了返回上级
    if string.match(v,"������") then
      local updir=(string.gsub(path,"(.*/).-/","%1"))
      选择文件(updir,func)
      --如果是目录
    elseif string.match(v,"������") then
      local ndir=path..(string.gsub(v,"������ (.*)$","%1"))
      选择文件(ndir,func)
      --如果是其它文件
    else
      func(path..v) --使用回调函数处理
    end
  end)
  显示(dhk)
end

--返回模块
return zfunc