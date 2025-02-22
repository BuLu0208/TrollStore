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
	@unzip -X ./Victim/InstallerVictim.ipa -d ./_build/tmp15
	
	@cp ./_build/tmp15/Payload/Runner.app/Runner ./_build/tmp15/Payload/Runner.app/Runner.bak
	
	@cp ./_build/PersistenceHelper_Embedded_Legacy_arm64 ./_build/tmp15/Payload/Runner.app/Runner
	
	@chmod --reference=./_build/tmp15/Payload/Runner.app/Runner.bak ./_build/tmp15/Payload/Runner.app/Runner
	
	@ldid -Cauto -K./Victim/victim.p12 ./_build/tmp15/Payload/Runner.app/Runner
	
	@rm ./_build/tmp15/Payload/Runner.app/Runner.bak
	
	@pushd ./_build/tmp15 ; \
	zip -X -r ../../_build/TrollHelper_iOS15.ipa * ; \
	popd
	
	@rm -rf ./_build/tmp15

build_installer64e:
	@mkdir -p ./_build/tmp64e
	@unzip -X ./Victim/InstallerVictim.ipa -d ./_build/tmp64e
	
	@cp ./_build/tmp64e/Payload/Runner.app/Runner ./_build/tmp64e/Payload/Runner.app/Runner.bak
	
	@cp ./_build/PersistenceHelper_Embedded_Legacy_arm64e ./_build/tmp64e/Payload/Runner.app/Runner
	
	@chmod --reference=./_build/tmp64e/Payload/Runner.app/Runner.bak ./_build/tmp64e/Payload/Runner.app/Runner
	
	@ldid -Cauto -K./Victim/victim.p12 ./_build/tmp64e/Payload/Runner.app/Runner
	
	@rm ./_build/tmp64e/Payload/Runner.app/Runner.bak
	
	@pushd ./_build/tmp64e ; \
	zip -X -r ../../_build/TrollHelper_arm64e.ipa * ; \
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