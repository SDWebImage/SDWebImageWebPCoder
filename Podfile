install! "cocoapods",
         :generate_multiple_pod_projects => true
         
use_frameworks!

example_project_path = 'Example/SDWebImageWebPCoderExample'
test_project_path = 'Tests/SDWebImageWebPCoderTests'
workspace 'SDWebImageWebPCoder.xcworkspace'

target 'SDWebImageWebPCoderExample' do
  platform :ios, '9.0'
  project example_project_path
  pod 'SDWebImageWebPCoder', :path => './'
end

target 'SDWebImageWebPCoderExample-macOS' do
  platform :osx, '10.11'
  project example_project_path
  pod 'SDWebImageWebPCoder', :path => './'
end

target 'SDWebImageWebPCoderTests' do
  platform :ios, '9.0'
  project test_project_path
  pod 'Expecta'
  pod 'SDWebImageWebPCoder', :path => './'
end

target 'SDWebImageWebPCoderTests-macOS' do
  platform :osx, '10.11'
  project test_project_path
  pod 'Expecta'
  pod 'SDWebImageWebPCoder', :path => './'
end


# Inject macro during SDWebImage Demo and Tests
post_install do |installer_representation|
  installer_representation.generated_projects.each do |project|
    project.targets.each do |target|
      if target.product_name == 'SDWebImageWebPCoder'
        target.build_configurations.each do |config|
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = '$(inherited) SD_CHECK_CGIMAGE_RETAIN_SOURCE=1'
        end
      else
        target.build_configurations.each do |config|
          # Override the min deployment target for some test specs to workaround `libarclite.a` missing issue
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
          config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.11'
          config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '9.0'
          config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '2.0'
          config.build_settings['XROS_DEPLOYMENT_TARGET'] = '1.0'
        end
      end
    end
  end
end