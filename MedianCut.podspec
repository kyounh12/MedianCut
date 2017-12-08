#
# Be sure to run `pod lib lint MedianCut.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MedianCut'
  s.version          = '0.2.5'
  s.summary          = 'Color selection library based on Median Cut algorithm'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Median Cut
Color selection library based on Median Cut algorithm.

                       DESC

  s.homepage         = 'https://github.com/kyounh12/MedianCut'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'junseok_lee' => 'kyounh12@snu.ac.kr' }
  s.source           = { :git => 'https://github.com/kyounh12/MedianCut.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'MedianCut/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MedianCut' => ['MedianCut/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
