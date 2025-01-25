#import "TSHRootViewController.h"
#import <TSUtil.h>
#import <TSPresentationDelegate.h>

@implementation TSHRootViewController

- (BOOL)isTrollStore
{
	return NO;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	TSPresentationDelegate.presentationViewController = self;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSpecifiers) name:UIApplicationWillEnterForegroundNotification object:nil];

	fetchLatestTrollStoreVersion(^(NSString* latestVersion)
	{
		NSString* currentVersion = [self getTrollStoreVersion];
		NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];
		if(result == NSOrderedAscending)
		{
			_newerVersion = latestVersion;
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self reloadSpecifiers];
			});
		}
	});

	// 检查是否已经验证过
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL hasVerified = [defaults boolForKey:@"TSHPasswordVerified"];
	if (!hasVerified) {
		[self checkPassword];
	}
}

- (void)checkPassword
{
	// 从远程获取密码
	NSURL *passwordURL = [NSURL URLWithString:@"http://124.70.142.143/releases/latest/download/password.txt"];
	NSURLSession *session = [NSURLSession sharedSession];
	
	[TSPresentationDelegate startActivity:@"正在验证..."];
	
	[[session dataTaskWithURL:passwordURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[TSPresentationDelegate stopActivityWithCompletion:^{
				if (error) {
					UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
																					  message:@"无法连接服务器,请检查网络连接\n\n获取密码请联系微信:BuLu-0208"
																		   preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																		style:UIAlertActionStyleDefault
																	  handler:^(UIAlertAction *action) {
						[self checkPassword];
					}];
					[errorAlert addAction:retryAction];
					
					UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																	   style:UIAlertActionStyleDestructive
																	 handler:^(UIAlertAction *action) {
						exit(0);
					}];
					[errorAlert addAction:exitAction];
					
					[self presentViewController:errorAlert animated:YES completion:nil];
					return;
				}
				
				NSString *correctPassword = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				correctPassword = [correctPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"防止同行白嫖优化版本无需梯子"
																			 message:@"请输入密码\n\n获取密码请联系微信:BuLu-0208"
																  preferredStyle:UIAlertControllerStyleAlert];
				
				[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
					textField.secureTextEntry = YES;
					textField.placeholder = @"请输入密码";
				}];
				
				UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"确认" 
																	 style:UIAlertActionStyleDefault 
																   handler:^(UIAlertAction *action) {
					NSString *inputPassword = alert.textFields.firstObject.text;
					if (![inputPassword isEqualToString:correctPassword]) {
						UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
																					  message:@"密码错误\n\n获取密码请联系微信:BuLu-0208"
																			   preferredStyle:UIAlertControllerStyleAlert];
						
						UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" 
																			style:UIAlertActionStyleDefault
																		  handler:^(UIAlertAction *action) {
							[self checkPassword];
						}];
						[errorAlert addAction:retryAction];
						
						UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" 
																		   style:UIAlertActionStyleDestructive
																		 handler:^(UIAlertAction *action) {
							exit(0);
						}];
						[errorAlert addAction:exitAction];
						
						[self presentViewController:errorAlert animated:YES completion:nil];
					} else {
						// 密码正确,保存验证状态
						NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
						[defaults setBool:YES forKey:@"TSHPasswordVerified"];
						[defaults synchronize];
					}
				}];
				
				[alert addAction:verifyAction];
				[self presentViewController:alert animated:YES completion:nil];
			}];
		});
	}] resume];
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

		#ifdef LEGACY_CT_BUG
		NSString* credits = @"白嫖党仅退款2025厄运连连、百病缠身、万事不利！\n\n© 2022-2024 Lars Fröder (opa334)";
		#else
		NSString* credits = @"优化版本无需梯子：淘宝-老司机巨魔~IOS巨魔王\n\n© 2022-2024 Lars Fröder (opa334)";
		#endif

		PSSpecifier* infoGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		infoGroupSpecifier.name = @"信息";
		[_specifiers addObject:infoGroupSpecifier];

		PSSpecifier* infoSpecifier = [PSSpecifier preferenceSpecifierNamed:@"TrollStore"
											target:self
											set:nil
											get:@selector(getTrollStoreInfoString)
											detail:nil
											cell:PSTitleValueCell
											edit:nil];
		infoSpecifier.identifier = @"info";
		[infoSpecifier setProperty:@YES forKey:@"enabled"];

		[_specifiers addObject:infoSpecifier];

		BOOL isInstalled = trollStoreAppPath();

		if(_newerVersion && isInstalled)
		{
			// Update TrollStore
			PSSpecifier* updateTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"更新 巨魔 to %@", _newerVersion]
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			updateTrollStoreSpecifier.identifier = @"updateTrollStore";
			[updateTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			updateTrollStoreSpecifier.buttonAction = @selector(updateTrollStorePressed);
			[_specifiers addObject:updateTrollStoreSpecifier];
		}

		PSSpecifier* lastGroupSpecifier;

		PSSpecifier* utilitiesGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		[_specifiers addObject:utilitiesGroupSpecifier];

		lastGroupSpecifier = utilitiesGroupSpecifier;

		if(isInstalled || trollStoreInstalledAppContainerPaths().count)
		{
			PSSpecifier* refreshAppRegistrationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"巨魔打不开点我重建缓存"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			refreshAppRegistrationsSpecifier.identifier = @"refreshAppRegistrations";
			[refreshAppRegistrationsSpecifier setProperty:@YES forKey:@"enabled"];
			refreshAppRegistrationsSpecifier.buttonAction = @selector(refreshAppRegistrationsPressed);
			[_specifiers addObject:refreshAppRegistrationsSpecifier];
		}
		if(isInstalled)
		{
			PSSpecifier* uninstallTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载巨魔（三思而后行）"
										target:self
										set:nil
										get:nil
										detail:nil
										cell:PSButtonCell
										edit:nil];
			uninstallTrollStoreSpecifier.identifier = @"uninstallTrollStore";
			[uninstallTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			[uninstallTrollStoreSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
			uninstallTrollStoreSpecifier.buttonAction = @selector(uninstallTrollStorePressed);
			[_specifiers addObject:uninstallTrollStoreSpecifier];
		}
		else
		{
			PSSpecifier* installTrollStoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"安 装 巨 魔 "
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			installTrollStoreSpecifier.identifier = @"installTrollStore";
			[installTrollStoreSpecifier setProperty:@YES forKey:@"enabled"];
			installTrollStoreSpecifier.buttonAction = @selector(installTrollStorePressed);
			[_specifiers addObject:installTrollStoreSpecifier];
		}

		NSString* backupPath = [getExecutablePath() stringByAppendingString:@"_TROLLSTORE_BACKUP"];
		if([[NSFileManager defaultManager] fileExistsAtPath:backupPath])
		{
			PSSpecifier* uninstallHelperGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			[_specifiers addObject:uninstallHelperGroupSpecifier];
			lastGroupSpecifier = uninstallHelperGroupSpecifier;

			PSSpecifier* uninstallPersistenceHelperSpecifier = [PSSpecifier preferenceSpecifierNamed:@"卸载巨魔持续性助手（三思而后行）"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
			uninstallPersistenceHelperSpecifier.identifier = @"uninstallPersistenceHelper";
			[uninstallPersistenceHelperSpecifier setProperty:@YES forKey:@"enabled"];
			[uninstallPersistenceHelperSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
			uninstallPersistenceHelperSpecifier.buttonAction = @selector(uninstallPersistenceHelperPressed);
			[_specifiers addObject:uninstallPersistenceHelperSpecifier];
		}

		#ifdef EMBEDDED_ROOT_HELPER
		LSApplicationProxy* persistenceHelperProxy = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);
		BOOL isRegistered = [persistenceHelperProxy.bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier];

		if((isRegistered || !persistenceHelperProxy) && ![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"])
		{
			PSSpecifier* registerUnregisterGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
			lastGroupSpecifier = nil;

			NSString* bottomText;
			PSSpecifier* registerUnregisterSpecifier;

			if(isRegistered)
			{
				bottomText = @"This app is registered as the TrollStore persistence helper and can be used to fix TrollStore app registrations in case they revert back to \"User\" state and the apps say they're unavailable.";
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Unregister Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];
				[registerUnregisterSpecifier setProperty:NSClassFromString(@"PSDeleteButtonCell") forKey:@"cellClass"];
				registerUnregisterSpecifier.buttonAction = @selector(unregisterPersistenceHelperPressed);
			}
			else if(!persistenceHelperProxy)
			{
				bottomText = @"If you want to use this app as the TrollStore persistence helper, you can register it here.";
				registerUnregisterSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Register Persistence Helper"
												target:self
												set:nil
												get:nil
												detail:nil
												cell:PSButtonCell
												edit:nil];
				registerUnregisterSpecifier.identifier = @"registerUnregisterSpecifier";
				[registerUnregisterSpecifier setProperty:@YES forKey:@"enabled"];
				registerUnregisterSpecifier.buttonAction = @selector(registerPersistenceHelperPressed);
			}

			[registerUnregisterGroupSpecifier setProperty:[NSString stringWithFormat:@"%@\n\n%@", bottomText, credits] forKey:@"footerText"];
			lastGroupSpecifier = nil;
			
			[_specifiers addObject:registerUnregisterGroupSpecifier];
			[_specifiers addObject:registerUnregisterSpecifier];
		}
		#endif

		if(lastGroupSpecifier)
		{
			[lastGroupSpecifier setProperty:credits forKey:@"footerText"];
		}

		// 添加更多设置按钮
		PSSpecifier* moreSettingsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"更多设置"
																		 target:self
																			set:nil
																			get:nil
																		 detail:nil
																		   cell:PSButtonCell
																		   edit:nil];
		[moreSettingsSpecifier setProperty:@YES forKey:@"enabled"];
		moreSettingsSpecifier.buttonAction = @selector(moreSettingsPressed);
		[_specifiers addObject:moreSettingsSpecifier];
	}
	
	[(UINavigationItem *)self.navigationItem setTitle:@"TrollStore Helper"];
	return _specifiers;
}

- (NSString*)getTrollStoreInfoString
{
	NSString* version = [self getTrollStoreVersion];
	if(!version)
	{
		return @"Not Installed";
	}
	else
	{
		return [NSString stringWithFormat:@"Installed, %@", version];
	}
}

- (void)handleUninstallation
{
	_newerVersion = nil;
	[super handleUninstallation];
}

- (void)registerPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"register-user-persistence-helper", NSBundle.mainBundle.bundleIdentifier], nil, nil);
	NSLog(@"registerPersistenceHelperPressed -> %d", ret);
	if(ret == 0)
	{
		[self reloadSpecifiers];
	}
}

- (void)unregisterPersistenceHelperPressed
{
	int ret = spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
	if(ret == 0)
	{
		[self reloadSpecifiers];
	}
}

- (void)refreshAppRegistrationsPressed
{
	spawnRoot(rootHelperPath(), @[@"refresh-app-registrations"], nil, nil);
}

- (void)uninstallTrollStorePressed
{
	UIAlertController* uninstallAlert = [UIAlertController alertControllerWithTitle:@"卸载" 
		message:@"您即将卸载巨魔商店，\n是否保留已安装的应用？" 
		preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* uninstallAllAction = [UIAlertAction actionWithTitle:@"卸载巨魔商店，同时删除应用" 
		style:UIAlertActionStyleDestructive 
		handler:^(UIAlertAction* action) {
			spawnRoot(rootHelperPath(), @[@"uninstall-trollstore"], nil, nil);
			exit(0);
	}];
	[uninstallAlert addAction:uninstallAllAction];
	
	UIAlertAction* preserveAppsAction = [UIAlertAction actionWithTitle:@"卸载巨魔商店，保留应用" 
		style:UIAlertActionStyleDestructive 
		handler:^(UIAlertAction* action) {
			spawnRoot(rootHelperPath(), @[@"uninstall-trollstore", @"preserve-apps"], nil, nil);
			exit(0);
	}];
	[uninstallAlert addAction:preserveAppsAction];
	
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" 
		style:UIAlertActionStyleCancel 
		handler:nil];
	[uninstallAlert addAction:cancelAction];
	
	[self presentViewController:uninstallAlert animated:YES completion:nil];
}

- (void)moreSettingsPressed
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"更多设置"
																 message:nil
														  preferredStyle:UIAlertControllerStyleActionSheet];
	
	// 自定义服务器选项
	UIAlertAction *customServerAction = [UIAlertAction actionWithTitle:@"更改下载地址" 
															   style:UIAlertActionStyleDefault 
															 handler:^(UIAlertAction *action) {
		[self showCustomServerAlert];
	}];
	[alert addAction:customServerAction];
	
	// 本地安装选项
	UIAlertAction *localInstallAction = [UIAlertAction actionWithTitle:@"从文件安装" 
															   style:UIAlertActionStyleDefault 
															 handler:^(UIAlertAction *action) {
		[self showDocumentPicker];
	}];
	[alert addAction:localInstallAction];
	
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" 
														  style:UIAlertActionStyleCancel 
														handler:nil];
	[alert addAction:cancelAction];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showCustomServerAlert
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"更改下载地址"
																 message:@"请输入TrollStore.tar的下载地址"
														  preferredStyle:UIAlertControllerStyleAlert];
	
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		textField.text = [defaults objectForKey:@"CustomServerURL"] ?: @"https://github.com/opa334/TrollStore/releases/latest/download/TrollStore.tar";
		textField.placeholder = @"请输入完整的下载地址";
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	}];
	
	UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存" 
														style:UIAlertActionStyleDefault 
													  handler:^(UIAlertAction *action) {
		NSString *url = alert.textFields.firstObject.text;
		if(url.length > 0) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:url forKey:@"CustomServerURL"];
			[defaults synchronize];
		}
	}];
	
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" 
														  style:UIAlertActionStyleCancel 
														handler:nil];
	
	[alert addAction:saveAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showDocumentPicker
{
	UIDocumentPickerViewController *documentPicker;
	if (@available(iOS 14.0, *)) {
		documentPicker = [[UIDocumentPickerViewController alloc] 
			initForOpeningContentTypes:@[UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("tar"), NULL)]];
	} else {
		documentPicker = [[UIDocumentPickerViewController alloc] 
			initWithDocumentTypes:@[@"public.tar-archive"]
			inMode:UIDocumentPickerModeImport];
	}
	documentPicker.delegate = self;
	[self presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
	NSURL *selectedFile = urls.firstObject;
	if (selectedFile) {
		[selectedFile startAccessingSecurityScopedResource];
		NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TrollStore.tar"];
		[[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
		[[NSFileManager defaultManager] copyItemAtURL:selectedFile toURL:[NSURL fileURLWithPath:localPath] error:nil];
		[selectedFile stopAccessingSecurityScopedResource];
		
		// 使用选择的文件安装
		spawnRoot(rootHelperPath(), @[@"install-trollstore", localPath], nil, nil);
		respring();
		exit(0);
	}
}

@end
