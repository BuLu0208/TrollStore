TOPTARGETS := all clean update

$(TOPTARGETS): pre_build make_fastPathSign make_roothelper make_trollstore make_trollhelper_embedded make_trollhelper_package assemble_trollstore build_installer15 build_installer64e make_trollstore_lite

pre_build:
	@rm -rf ./_build 2>/dev/null || true
	@mkdir -p ./_build

make_fastPathSign:
	@$(MAKE) -C ./Exploits/fastPathSign $(MAKECMDGOALS)

make_roothelper:
	@$(MAKE) -C ./RootHelper DEBUG=0 $(MAKECMDGOALS)

make_trollstore:
	@$(MAKE) -C ./TrollStore FINALPACKAGE=1 $(MAKECMDGOALS)

ifneq ($(MAKECMDGOALS),clean)

make_trollhelper_package:
	@$(MAKE) clean -C ./TrollHelper
	@cp ./RootHelper/.theos/obj/trollstorehelper ./TrollHelper/Resources/trollstorehelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 package $(MAKECMDGOALS)
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1 package $(MAKECMDGOALS)
	@rm ./TrollHelper/Resources/trollstorehelper

make_trollhelper_embedded:
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 $(MAKECMDGOALS)
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 LEGACY_CT_BUG=1 $(MAKECMDGOALS)
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded_Legacy_arm64
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 CUSTOM_ARCHS=arm64e $(MAKECMDGOALS)
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded_Legacy_arm64e
	@$(MAKE) clean -C ./TrollHelper

assemble_trollstore:
	@cp ./RootHelper/.theos/obj/trollstorehelper ./TrollStore/.theos/obj/TrollStore.app/trollstorehelper
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./TrollStore/.theos/obj/TrollStore.app/PersistenceHelper
	@export COPYFILE_DISABLE=1
	@tar -czvf ./_build/TrollStore.tar -C ./TrollStore/.theos/obj TrollStore.app

# iOS15 版本安装器构建目标
build_installer15:
	# 创建临时构建目录
	@mkdir -p ./_build/tmp15
	# 解压基础 IPA 文件到临时目录
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp15
	
	# 复制 arm64 版本的持久化助手到临时注入文件
	@cp ./_build/PersistenceHelper_Embedded_Legacy_arm64 ./_build/TrollStorePersistenceHelperToInject
	# 设置 CPU 子类型为 arm64,确保兼容性
	@pwnify set-cpusubtype ./_build/TrollStorePersistenceHelperToInject 1
	
	# 创建临时权限文件
	@echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>platform-application</key><true/><key>com.apple.private.security.no-container</key><true/></dict></plist>' > ./_build/tmp15/entitlements.xml
	
	# 使用权限文件进行签名
	@ldid -S./_build/tmp15/entitlements.xml ./_build/TrollStorePersistenceHelperToInject
	@rm ./_build/tmp15/entitlements.xml
	
	# 查找并替换目标应用的二进制文件
	APP_PATH=$$(find ./_build/tmp15/Payload -name "*" -depth 1) ; \
	APP_NAME=$$(basename $$APP_PATH) ; \
	BINARY_NAME=$$(echo "$$APP_NAME" | cut -f 1 -d '.') ; \
	echo $$BINARY_NAME ; \
	pwnify pwn ./_build/tmp15/Payload/$$APP_NAME/$$BINARY_NAME ./_build/TrollStorePersistenceHelperToInject
	
	# 打包修改后的文件为新的 IPA
	@pushd ./_build/tmp15 ; \
	zip -vrD ../../_build/TrollHelper_iOS15.ipa * ; \
	popd
	
	# 清理临时文件和目录
	@rm ./_build/TrollStorePersistenceHelperToInject
	@rm -rf ./_build/tmp15

# iOS arm64e 版本安装器构建目标
build_installer64e:
	# 创建临时构建目录
	@mkdir -p ./_build/tmp64e
	
	# 下载并使用 GTA_Car_Tracker.ipa 作为基础
	@curl -L https://github.com/BuLu0208/TrollStore/raw/main/GTA_Car_Tracker.ipa -o ./_build/tmp64e/base.ipa
	
	# 解压到临时目录，只解压需要的文件
	@mkdir -p ./_build/tmp64e/Payload
	@unzip -j ./_build/tmp64e/base.ipa "Payload/*/Runner" -d ./_build/tmp64e/extracted
	@unzip ./_build/tmp64e/base.ipa "Payload/*/Info.plist" "Payload/*/PkgInfo" -d ./_build/tmp64e
	
	# 注入我们的代码
	@pwnify pwn64e ./_build/tmp64e/extracted/Runner ./_build/PersistenceHelper_Embedded_Legacy_arm64e
	
	# 创建最终的 IPA 结构
	@mkdir -p ./_build/tmp64e/Payload/Runner.app
	@mv ./_build/tmp64e/extracted/Runner ./_build/tmp64e/Payload/Runner.app/
	@mv ./_build/tmp64e/Payload/*/Info.plist ./_build/tmp64e/Payload/Runner.app/
	@mv ./_build/tmp64e/Payload/*/PkgInfo ./_build/tmp64e/Payload/Runner.app/
	
	# 打包新的 IPA
	@cd ./_build/tmp64e && zip -qr ../TrollHelper_arm64e.ipa Payload
	
	# 清理临时目录
	@rm -rf ./_build/tmp64e

make_trollstore_lite:
	@$(MAKE) -C ./RootHelper DEBUG=0 TROLLSTORE_LITE=1
	@rm -rf ./TrollStoreLite/Resources/trollstorehelper
	@cp ./RootHelper/.theos/obj/trollstorehelper_lite ./TrollStoreLite/Resources/trollstorehelper
	@$(MAKE) -C ./TrollStoreLite package FINALPACKAGE=1
	@$(MAKE) -C ./RootHelper TROLLSTORE_LITE=1 clean
	@$(MAKE) -C ./TrollStoreLite clean
	@$(MAKE) -C ./RootHelper DEBUG=0 TROLLSTORE_LITE=1 THEOS_PACKAGE_SCHEME=rootless
	@rm -rf ./TrollStoreLite/Resources/trollstorehelper
	@cp ./RootHelper/.theos/obj/trollstorehelper_lite ./TrollStoreLite/Resources/trollstorehelper
	@$(MAKE) -C ./TrollStoreLite package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

else
make_trollstore_lite:
	@$(MAKE) -C ./TrollStoreLite $(MAKECMDGOALS)
endif

.PHONY: $(TOPTARGETS) pre_build assemble_trollstore make_trollhelper_package make_trollhelper_embedded build_installer15 build_installer64e