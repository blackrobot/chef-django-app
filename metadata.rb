name             "django-application"
maintainer       "blackrobot"
maintainer_email "damonjablons@gmail.com"
license          "Apache 2.0"
description      "An opinionated deployment for Django applications"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"
# recipe           "application", "Empty placeholder recipe, use the LWRPs, see README.md."

%w{ nginx application python supervisor database mysql }.each do |dep|
  depends dep
end

supports "ubuntu"
