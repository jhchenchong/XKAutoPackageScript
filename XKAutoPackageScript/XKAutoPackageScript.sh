# 原作者
# ################################################################################
# 
# 联系方式 :
# Weibo : jkpang-庞 http://weibo.com/u/5743737098/home?wvr=5&uut=fin&from=reg
# Email : jkpang@outlook.com
# QQ 群 : 323408051
# GitHub: https://github.com/jkpang
#
# ################################################################################
#

# 使用方法:(因为在使用过程中发现了些小问题 自己加上了上传内测平台的选项)
# step1 : 将XKAutoPackageScript整个文件夹拖入到项目主目录,项目主目录,项目主目录~~~(重要的事情说3遍!😊😊😊)
# step2 : 打开XKAutoPackageScript.sh文件,修改 "项目自定义部分"和"项目上传部分" 配置好项目参数 如果没有配置项目上传参数 在选择内测网站的时候请选择1或者不为1234的其他任何字符然后回车
# step3 : 打开终端, cd到XKAutoPackageScript文件夹 (ps:在终端中先输入cd ,直接拖入XKAutoPackageScript文件夹,回车)
# step4 : 输入 sh XKAutoPackageScript.sh 命令,回车,开始执行此打包脚本

# ===============================项目自定义部分(自定义好下列参数后再执行该脚本)============================= #
# 计时
SECONDS=0
# 是否编译工作空间 (例:若是用Cocopods管理的.xcworkspace项目,赋值true;用Xcode默认创建的.xcodeproj,赋值false)
is_workspace="true"
# 指定项目的scheme名称
# (注意: 因为shell定义变量时,=号两边不能留空格,若scheme_name与info_plist_name有空格,脚本运行会失败,暂时还没有解决方法,知道的还请指教!)
scheme_name="scheme_name"
# 工程中Target对应的配置plist文件名称, Xcode默认的配置文件为Info.plist
info_plist_name="Info"
# 指定要打包编译的方式 : Release,Debug AdHoc...
build_configuration="Release"

# ===============================项目上传部分============================= #
# 上传到fir <https://fir.im>，
# 需要先安装fir的命令行工具 
# gem install fir-cli(如果安装过程报错 可以尝试 sudo gem install fir-cli -n /usr/local/bin)
# 在 fir 上的API Token
fir_token="your_api_token"

# 上传到蒲公英
pgyer_u_key="your User Key"
pgyer_api_key="your API Key"


# ===============================自动打包部分(无特殊情况不用修改)============================= #

# 导出ipa所需要的plist文件路径 (默认为AdHocExportOptionsPlist.plist)
ExportOptionsPlistPath="./XKAutoPackageScript/AdHocExportOptionsPlist.plist"
# 返回上一级目录,进入项目工程目录
cd ..
# 获取项目名称
project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
# 获取版本号,内部版本号,bundleID (这里需要注意的是 如果您的Info.plist文件不是默认的工程目录下这里需要修改 例如 我的工程的plist文件是/项目名/项目名/SupportingFiles/Info.plist 对应的要修改为info_plist_path="$project_name/SupportingFiles/$info_plist_name.plist")
info_plist_path="$project_name/$info_plist_name.plist"
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $info_plist_path`
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $info_plist_path`
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $info_plist_path`

# 删除旧.xcarchive文件
rm -rf ~/Desktop/$scheme_name-IPA/$scheme_name.xcarchive
# 指定输出ipa路径
export_path=~/Desktop/$scheme_name-IPA
# 指定输出归档文件地址
export_archive_path="$export_path/$scheme_name.xcarchive"
# 指定输出ipa地址
export_ipa_path="$export_path"
# 指定输出ipa名称 : scheme_name + bundle_version
ipa_name="$scheme_name-v$bundle_version"

# AdHoc,AppStore,Enterprise三种打包方式的区别: http://blog.csdn.net/lwjok2007/article/details/46379945
echo "\033[36;1m请选择打包方式(输入序号,按回车即可) \033[0m"
echo "\033[33;1m1. AdHoc       \033[0m"
echo "\033[33;1m2. AppStore    \033[0m"
echo "\033[33;1m3. Enterprise  \033[0m"
echo "\033[33;1m4. Development \033[0m"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
    if [ "$method" = "1" ] ; then
    ExportOptionsPlistPath="./XKAutoPackageScript/AdHocExportOptionsPlist.plist"
    elif [ "$method" = "2" ] ; then
    ExportOptionsPlistPath="./XKAutoPackageScript/AppStoreExportOptionsPlist.plist"
    elif [ "$method" = "3" ] ; then
    ExportOptionsPlistPath="./XKAutoPackageScript/EnterpriseExportOptionsPlist.plist"
    elif [ "$method" = "4" ] ; then
    ExportOptionsPlistPath="./XKAutoPackageScript/DevelopmentExportOptionsPlist.plist"
    else
    echo "输入的参数无效!!!"
    exit 1
    fi
fi

# 选择内测网站 用Fir或者pgyer
echo "\033[36;1m请选择ipa内测发布平台 (输入序号, 按回车即可) \033[0m"
echo "\033[33;1m1. None \033[0m"
echo "\033[33;1m2. Pgyer \033[0m"
echo "\033[33;1m3. Fir \033[0m"
echo "\033[33;1m4. Pgyer and Fir \033[0m\n"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
upload_type="$parameter"

echo "\033[36;1m**************************开始编译代码...*********************************\033[0m"
# 指定输出文件目录不存在则创建
if [ -d "$export_path" ] ; then
echo $export_path
else
mkdir -pv $export_path
fi

# 判断编译的项目类型是workspace还是project
if $is_workspace ; then
# 编译前清理工程
xcodebuild clean -workspace ${project_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${project_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
else
# 编译前清理工程
xcodebuild clean -project ${project_name}.xcodeproj \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -project ${project_name}.xcodeproj \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
fi

#  检查是否构建成功
#  xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$export_archive_path" ] ; then
echo "\033[36;1m✅  ✅  ✅  ✅  ✅  ✅  编译成功  ✅  ✅  ✅  ✅  ✅  ✅  \033[0m"
else
echo "\033[36;1m❌  ❌  ❌  ❌  ❌  ❌  编译失败  ❌  ❌  ❌  ❌  ❌  ❌  \033[0m"
exit 1
fi

echo "\033[36;**************************开始导出ipa文件....*********************************\033[0m"
xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${ExportOptionsPlistPath} \
            -allowProvisioningUpdates
# 修改ipa文件名称
mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

# 检查文件是否存在
if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
echo "\033[36;1m🎉  🎉  🎉  🎉  🎉  🎉  ${ipa_name} 打包成功! 🎉  🎉  🎉  🎉  🎉  🎉  \033[0m"
open $export_path
else
echo "\033[36;1m ❌  ❌  ❌  ❌  ❌  ❌  ${ipa_name} 打包失败! ❌  ❌  ❌  ❌  ❌  ❌  \033[0m"
exit 1
fi
# 输出打包总用时
echo "\033[36;1m使用XKAutoPackageScript打包总用时: ${SECONDS}s \033[0m"

# 上传
if [[ "${upload_type}" == "1" ]] ; then
echo "\033[36;1m ❌  ❌  ❌  ❌  ❌  ❌  您选择了不上传到内测网站  ❌  ❌  ❌  ❌  ❌  ❌  \033[0m"
elif [[ "${upload_type}" == "2" ]]; then
curl -F "file=@$export_ipa_path/$ipa_name.ipa" \
-F "uKey=$pgyer_u_key" \
-F "_api_key=$pgyer_api_key" \
"http://www.pgyer.com/apiv1/app/upload"
echo "\033[36;1m ✅  ✅  ✅  ✅  ✅  ✅  上传蒲公英成功  ✅  ✅  ✅  ✅  ✅  ✅  \033[0m"
echo "\033[36;1m使用XKAutoPackageScript打包上传蒲公英总用时: ${SECONDS}s \033[0m"
elif [[ "${upload_type}" == "3" ]]; then
fir publish "$export_ipa_path/$ipa_name.ipa" -T ${fir_token}
echo "\033[36;1m ✅  ✅  ✅  ✅  ✅  ✅  上传fir成功    ✅  ✅  ✅  ✅  ✅  ✅  \033[0m"
echo "\033[36;1m使用XKAutoPackageScript打包上传fir总用时: ${SECONDS}s \033[0m"
elif [[ "${upload_type}" == "4" ]]; then
curl -F "file=@$export_ipa_path/$ipa_name.ipa" \
-F "uKey=$pgyer_u_key" \
-F "_api_key=$pgyer_api_key" \
"http://www.pgyer.com/apiv1/app/upload"
echo "\033[36;1m ✅  ✅  ✅  ✅  ✅  ✅  上传蒲公英成功  ✅  ✅  ✅  ✅  ✅  ✅  \033[0m"
fir publish "$export_ipa_path/$ipa_name.ipa" -T ${fir_token}
echo "\033[36;1m ✅  ✅  ✅  ✅  ✅  ✅  上传fir成功    ✅  ✅  ✅  ✅  ✅  ✅  \033[0m"
echo "\033[36;1m使用XKAutoPackageScript打包上传蒲公英和fir总用时: ${SECONDS}s \033[0m"
else
echo "\033[36;1m ❌  ❌  ❌  ❌  ❌  ❌ 您输入的上传内测网站参数无效 ❌  ❌  ❌  ❌  ❌  ❌ \033[0m"
exit 1
fi
