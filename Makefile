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
	@mkdir -p ./_build/tmp15 ./_build/tmp64e
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp15
	@unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp64e
	
	# 编译标准版本
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 $(MAKECMDGOALS)
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded
	
	# 编译 Legacy arm64 版本
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 LEGACY_CT_BUG=1 $(MAKECMDGOALS)
	@cp -r ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/* ./_build/tmp15/Payload/Runner.app/
	
	# 编译 arm64e 版本
	@$(MAKE) clean -C ./TrollHelper
	@$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 CUSTOM_ARCHS=arm64e $(MAKECMDGOALS)
	@cp -r ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/* ./_build/tmp64e/Payload/Runner.app/

assemble_trollstore:
	@cp ./RootHelper/.theos/obj/trollstorehelper ./TrollStore/.theos/obj/TrollStore.app/trollstorehelper
	@cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./TrollStore/.theos/obj/TrollStore.app/PersistenceHelper
	@export COPYFILE_DISABLE=1
	@tar -czvf ./_build/TrollStore.tar -C ./TrollStore/.theos/obj TrollStore.app

build_installer15:
	# 重新签名
	@echo "重新签名..."
	@ldid -S ./_build/tmp15/Payload/Runner.app/Runner
	
	# 打包 iOS15 版本
	@pushd ./_build/tmp15 ; \
	zip -vrD ../../_build/TrollHelper_iOS15.ipa * ; \
	popd
	@rm -rf ./_build/tmp15

build_installer64e:
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