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

build_installer15:
	@mkdir -p ./_build/tmp15
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp15
	
	# 先检查 PersistenceHelper 是否包含中文字符串
	@echo "检查 PersistenceHelper 是否包含中文字符串..."
	@otool -v -s __TEXT __cstring ./_build/PersistenceHelper_Embedded_Legacy_arm64 | grep "更多设置" || echo "PersistenceHelper 中未找到中文字符串!"
	@otool -v -s __TEXT __cstring ./_build/PersistenceHelper_Embedded_Legacy_arm64 | grep "防止同行白嫖" || echo "PersistenceHelper 中未找到中文字符串!"
	@otool -v -s __TEXT __cstring ./_build/PersistenceHelper_Embedded_Legacy_arm64 | grep "获取密码请联系微信" || echo "PersistenceHelper 中未找到中文字符串!"
	
	# 使用 Legacy arm64 版本替换 Runner
	@echo "替换 Runner 二进制 (arm64)..."
	@cp ./_build/PersistenceHelper_Embedded_Legacy_arm64 ./_build/tmp15/Payload/Runner.app/Runner
	
	# 重新签名
	@echo "重新签名..."
	@ldid -S ./_build/tmp15/Payload/Runner.app/Runner
	
	# 验证替换后的 Runner
	@echo "验证替换后的 Runner..."
	@otool -v -s __TEXT __cstring ./_build/tmp15/Payload/Runner.app/Runner | grep "更多设置" || echo "替换后的 Runner 中未找到中文字符串!"
	
	# 打包 iOS15 版本
	@pushd ./_build/tmp15 ; \
	zip -vrD ../../_build/TrollHelper_iOS15.ipa * ; \
	popd
	@rm -rf ./_build/tmp15

build_installer64e:
	@mkdir -p ./_build/tmp64e
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp64e
	
	# 使用 arm64e 版本替换 Runner
	@echo "替换 Runner 二进制 (arm64e)..."
	@cp ./_build/PersistenceHelper_Embedded_Legacy_arm64e ./_build/tmp64e/Payload/Runner.app/Runner
	
	# 重新签名
	@echo "重新签名..."
	@ldid -S ./_build/tmp64e/Payload/Runner.app/Runner
	
	# 打包 arm64e 版本
	@pushd ./_build/tmp64e ; \
	zip -vrD ../../_build/TrollHelper_arm64e.ipa * ; \
	popd
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