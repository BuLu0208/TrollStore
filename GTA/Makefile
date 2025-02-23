.PHONY: all clean

all:
	# 创建工作目录
	@mkdir -p work
	
	# 解压原始 IPA
	@echo "Extracting original IPA..."
	@unzip -q GTA_Car_Tracker.ipa -d work
	
	# 注入新的助手代码
	@echo "Injecting new helper..."
	@pwnify pwn64e work/Payload/Runner.app/Runner PersistenceHelper_Embedded_Legacy_arm64e
	
	# 确保权限正确
	@chmod 755 work/Payload/Runner.app/Runner
	
	# 打包新的 IPA
	@echo "Creating patched IPA..."
	@cd work && zip -qr ../TrollHelper_Patched.ipa Payload
	
	@echo "Done! Check TrollHelper_Patched.ipa"

clean:
	@rm -rf work TrollHelper_Patched.ipa 