Pod::Spec.new do |spec|

	spec.name = 'XCGLogger'
	spec.version = '4.0.0'
	spec.summary = 'A debug log module for use in Swift projects.'

	spec.description = <<-DESC
						Allows you to log details to the console (and optionally a file), just like you would have with NSLog() or print(), but with additional information, such as the date, function name, filename and line number.
						DESC

	spec.homepage = 'https://github.com/DaveWoodCom/XCGLogger'

	spec.license = { :type => 'MIT', :file => 'LICENSE.txt' }
	spec.author = { 'Dave Wood' => 'cocoapods@cerebralgardens.com' }
	spec.social_media_url = 'http://twitter.com/DaveWoodX'
	spec.platforms = { :ios => '7.0', :watchos => '2.0', :tvos => '9.0' }
	spec.requires_arc = true

	spec.source = { :git => 'https://github.com/DaveWoodCom/XCGLogger.git', :tag => 'Version_4.0.0' }

	spec.ios.deployment_target = '8.0'
	spec.osx.deployment_target = '10.10'
	spec.watchos.deployment_target = '2.0'
	spec.tvos.deployment_target = '9.0'
	
	spec.default_subspec = 'Core'

	# Main XCGLogger Framework	
	spec.subspec 'Core' do |core|
		core.source_files = 'Sources/XCGLogger/**/*.{swift,h,m}'
		core.exclude_files = 'Sources/XCGLogger/**/Optional/*.{swift,h,m}'
	end

	# An experimental subspec to include helpers for using the UserInfo dictionary with log messages, tagging logs with tags and/or developers
	spec.subspec 'UserInfoHelpers' do |userinfohelpers|
		userinfohelpers.dependency 'XCGLogger/Core'
		userinfohelpers.source_files = 'Sources/XCGLogger/Misc/Optional/UserInfoHelpers.swift'
	end

end
