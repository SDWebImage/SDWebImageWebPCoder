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
