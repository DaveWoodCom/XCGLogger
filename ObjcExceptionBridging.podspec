Pod::Spec.new do |spec|

    spec.name = 'ObjcExceptionBridging'
    spec.version = '7.0.1'
    spec.summary = 'A bridge to Objective-C exception handling, for use in Swift projects.'

    spec.description = <<-DESC
                        For use in XCGLogger only at this point, untested as an independent library
                        DESC

    spec.homepage = 'https://github.com/DaveWoodCom/XCGLogger'

    spec.license = { :type => 'MIT', :file => 'LICENSE.txt' }
    spec.author = { 'Dave Wood' => 'cocoapods@cerebralgardens.com' }
    spec.social_media_url = 'https://mastodon.social/@davewoodx'
    spec.platforms = { :ios => '15.0', :watchos => '9.0', :tvos => '15.0' }
    spec.requires_arc = true

    spec.source = { :git => 'https://github.com/DaveWoodCom/XCGLogger.git', :tag => '7.0.1' }

    spec.ios.deployment_target = '15.0'
    spec.osx.deployment_target = '13.0'
    spec.watchos.deployment_target = '9.0'
    spec.tvos.deployment_target = '15.0'
    
    spec.default_subspecs = 'ObjcExceptionBridging'

    # ObjcExceptionBridging Framework
    spec.subspec 'ObjcExceptionBridging' do |core|
        core.source_files = 'Sources/ObjcExceptionBridging/**/*.{h,m}'
        core.resource = 'Sources/ObjcExceptionBridging/PrivacyInfo.xcprivacy'
    end
end
