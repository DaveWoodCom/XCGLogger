Pod::Spec.new do |spec|

    spec.name = 'ObjcExceptionBridging'
    spec.version = '7.1.5'
    spec.summary = 'A bridge to Objective-C exception handling, for use in Swift projects.'

    spec.description = <<-DESC
                        For use in XCGLogger only at this point, untested as an independent library
                        DESC

    spec.homepage = 'https://github.com/DaveWoodCom/XCGLogger'

    spec.license = { :type => 'MIT', :file => 'LICENSE.txt' }
    spec.author = { 'Dave Wood' => 'cocoapods@cerebralgardens.com' }
    spec.social_media_url = 'https://mastodon.social/@davewoodx'
    spec.platforms = { :ios => '12.0', :watchos => '4.0', :tvos => '12.0', :osx => '10.13' }
    spec.requires_arc = true
    spec.cocoapods_version = '>= 1.13.0'

    spec.source = { :git => 'https://github.com/DaveWoodCom/XCGLogger.git', :tag => "#{spec.version}" }

    spec.ios.deployment_target = '12.0'
    spec.osx.deployment_target = '10.13'
    spec.watchos.deployment_target = '4.0'
    spec.tvos.deployment_target = '12.0'
    
    spec.default_subspecs = 'ObjcExceptionBridging'

    # ObjcExceptionBridging Framework
    spec.subspec 'ObjcExceptionBridging' do |core|
        core.source_files = 'Sources/ObjcExceptionBridging/**/*.{h,m}'
        core.resource_bundles = {
            "#{spec.name}" => [
            	'Sources/ObjcExceptionBridging/PrivacyInfo.xcprivacy',
            ]
        }        
    end
end
