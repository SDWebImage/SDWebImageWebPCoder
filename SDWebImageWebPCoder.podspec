Pod::Spec.new do |s|
  s.name             = 'SDWebImageWebPCoder'
  s.version          = '0.1.2'
  s.summary          = 'WebP decoder/encoder for SDWebImage coder plugin.'

  s.description      = <<-DESC
This is a simple SDWebImage coder plugin to support WebP image.
                       DESC

  s.homepage         = 'https://github.com/SDWebImage/SDWebImageWebPCoder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bogdan Poplauschi' => 'bpoplauschi@gmail.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  
  s.source_files = 'SDWebImageWebPCoder/Classes/**/*'
  s.xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SD_WEBP=1',
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
  }
  s.watchos.xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SD_WEBP=1 WEBP_USE_INTRINSICS=1',
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
  }
  s.dependency 'SDWebImage/Core', '>= 5.0.0-beta4'
  s.dependency 'libwebp', '~> 1.0'
  
end
