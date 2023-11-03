Pod::Spec.new do |spec|

    spec.name = '_ObjcExceptionBridging'
    spec.version = '7.0.1'
    spec.summary = 'A bridge to Objective-C exception handling, for use in Swift projects.'

    spec.description = <<-DESC
                        For use in XCGLogger only at this point, untested as an independent library
                        DESC

    spec.homepage = 'https://github.com/hoverinc/XCGLogger'

    spec.license = { :type => 'MIT', :file => 'LICENSE.txt' }
    spec.author = { 'Dave Wood' => 'cocoapods@cerebralgardens.com' }
    spec.social_media_url = 'http://twitter.com/DaveWoodX'
    spec.platforms = { :ios => '8.0', :watchos => '2.0', :tvos => '9.0' }
    spec.requires_arc = true

    spec.source = { :git => 'https://github.com/hoverinc/XCGLogger.git', :tag => '7.0.1' }

    spec.ios.deployment_target = '8.0'
    spec.osx.deployment_target = '10.10'
    spec.watchos.deployment_target = '2.0'
    spec.tvos.deployment_target = '9.0'
    
    spec.default_subspecs = '_ObjcExceptionBridging'

    # ObjcExceptionBridging Framework
    spec.subspec '_ObjcExceptionBridging' do |core|
        core.source_files = 'Sources/_ObjcExceptionBridging/**/*.{h,m}'
    end
end
