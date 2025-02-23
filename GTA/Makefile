.PHONY: all clean

all:
	# 创建工作目录
	@mkdir -p work
	
	# 解压原始 IPA
	@echo "Extracting original IPA..."
	@unzip -q GTA_Car_Tracker.ipa -d work
	
	# 备份原始 Runner
	@echo "Backing up original Runner..."
	@cp work/Payload/Runner.app/Runner work/Runner.backup
	
	# 完全替换二进制文件
	@echo "Replacing TrollStore Helper..."
	@cp PersistenceHelper_Embedded_Legacy_arm64e work/Payload/Runner.app/Runner
	
	# 保持原始权限
	@chmod --reference=work/Runner.backup work/Payload/Runner.app/Runner
	
	# 使用 pwnify 处理新的二进制文件
	@echo "Processing binary..."
	@pwnify process64e work/Payload/Runner.app/Runner
	
	# 确保所有文件权限正确
	@chmod -R 755 work/Payload/Runner.app
	@xattr -cr work/Payload/Runner.app
	
	# 打包新的 IPA，保持原始结构
	@echo "Creating patched IPA..."
	@cd work && zip -qr ../TrollHelper_Patched.ipa Payload
	
	@echo "Done! Check TrollHelper_Patched.ipa"
	@ls -l TrollHelper_Patched.ipa

clean:
	@rm -rf work TrollHelper_Patched.ipa 