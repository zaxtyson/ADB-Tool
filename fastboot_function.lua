require "zfunc"
设置页面布局("fastboot_function_lay")

--接受的参数设备id保存在...里面
dev_id = ...

设置标题栏("FASTBOOT : "..dev_id,0xffFFFFFF,0xffC62828)

reboot.onClick=function(view)
  local dhk = 对话框()
  设置对话框(dhk,"标题","选择重启方式")
  设置对话框(dhk,"积极按钮","fastboot",function()
    sushell("fastboot -s "..dev_id.." reboot-bootloader")
    下方提示("重启到fastboot模式")
  end)
  设置对话框(dhk,"中立按钮","正常重启",function()
    sushell("fastboot -s "..dev_id.." reboot")
    下方提示("正常重启")
  end)
  显示(dhk)
end

flash.onClick=function(view)
  
end

