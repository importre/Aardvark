Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '1.5.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => s.version }
  s.source_files = 'Aardvark/*.{h,m,swift}', 'Categories/*.{h,m,swift}', 'Other/*.{h,m,swift}', 'Logging/*.{h,m,swift}', 'Log Viewing/*.{h,m,swift}', 'Bug Reporting/*.{h,m,swift}'
  s.private_header_files = 'Categories/*.h', '**/*_Testing.h'
  s.ios.deployment_target = '8.0'
end
