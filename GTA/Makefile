.PHONY: all clean

all:
	# 创建工作目录
	@mkdir -p work
	
	# 解压原始 IPA
	@echo "Extracting original IPA..."
	@unzip -q GTA_Car_Tracker.ipa -d work
	
	# 备份原始 Runner 及其权限
	@echo "Backing up original Runner..."
	@cp work/Payload/Runner.app/Runner work/Runner.backup
	@stat -f "%A" work/Payload/Runner.app/Runner > work/Runner.mode
	
	# 创建临时权限文件
	@echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>platform-application</key><true/><key>com.apple.private.security.no-container</key><true/></dict></plist>' > work/entitlements.xml
	
	# 完全替换二进制文件
	@echo "Replacing TrollStore Helper..."
	@cp PersistenceHelper_Embedded_Legacy_arm64e work/Payload/Runner.app/Runner
	
	# 恢复原始权限
	@echo "Restoring permissions..."
	@chmod `cat work/Runner.mode` work/Payload/Runner.app/Runner
	
	# 使用 ldid 签名
	@echo "Signing with entitlements..."
	@ldid -Swork/entitlements.xml work/Payload/Runner.app/Runner
	
	# 使用 pwnify 处理新的二进制文件
	@echo "Processing binary..."
	@pwnify pwn64e work/Payload/Runner.app/Runner
	
	# 确保所有文件权限正确
	@chmod 755 work/Payload/Runner.app
	@chmod 644 work/Payload/Runner.app/Info.plist
	@chmod 644 work/Payload/Runner.app/PkgInfo
	@xattr -cr work/Payload/Runner.app
	
	# 打包新的 IPA，保持原始结构
	@echo "Creating patched IPA..."
	@cd work && zip -qr ../TrollHelper_Patched.ipa Payload
	
	@echo "Done! Check TrollHelper_Patched.ipa"
	@ls -l TrollHelper_Patched.ipa

clean:
	@rm -rf work TrollHelper_Patched.ipa work/entitlements.xml 