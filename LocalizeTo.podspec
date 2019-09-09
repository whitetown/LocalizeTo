
Pod::Spec.new do |s|

  s.name         = "LocalizeTo"
  s.version      = "0.0.1"
  s.summary      = "Swift SDK for LocalizeTo service"
  s.description  = <<-DESC
  This module allows you to get localization strings from Localize.to[https://localize.to] service.
  It's nice and flexible replacement for native iOS localization files.
                   DESC
  s.homepage     = "https://github.com/whitetown/LocalizeTo"
  s.license      = { :type => "MIT" }
  s.author       = { "WhiteTown" => "whitetownmail@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/whitetown/LocalizeTo.git", :tag => "v0.0.1" }
  s.source_files = "LocalizeTo", "LocalizeTo/**/*.{h,m,swift}"
  s.swift_version = '5.0'

end
