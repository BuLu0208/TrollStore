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
	# 使用受害者证书对注入文件进行签名
	@ldid -s -K./Victim/victim.p12 ./_build/TrollStorePersistenceHelperToInject
	
	# 查找并替换目标应用的二进制文件
	# 1. 查找 Payload 目录下的应用目录
	# 2. 获取应用目录名称
	# 3. 提取应用二进制文件名
	# 4. 使用 pwnify 工具注入持久化助手
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
	# 解压基础 IPA 文件到临时目录
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp64e
	
	# 查找并替换目标应用的二进制文件(arm64e 版本)
	# 使用相同的查找逻辑,但使用 arm64e 特定的注入命令
	APP_PATH=$$(find ./_build/tmp64e/Payload -name "*" -depth 1) ; \
	APP_NAME=$$(basename $$APP_PATH) ; \
	BINARY_NAME=$$(echo "$$APP_NAME" | cut -f 1 -d '.') ; \
	echo $$BINARY_NAME ; \
	pwnify pwn64e ./_build/tmp64e/Payload/$$APP_NAME/$$BINARY_NAME ./_build/PersistenceHelper_Embedded_Legacy_arm64e
	
	# 打包修改后的文件为新的 IPA
	@pushd ./_build/tmp64e ; \
	zip -vrD ../../_build/TrollHelper_arm64e.ipa * ; \
	popd
	
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