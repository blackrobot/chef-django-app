#
# Cookbook Name:: django-app
# Recipe:: python
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#


# Install the image libraries
%w{ libjpeg62 libjpeg62-dev libmemcached-dev
    zlib1g-dev zlibc zlib1g }.each do |pkg|
  package pkg do
    action :install
  end
end

# If Ubuntu and x86, symlink the x86 libs to the
# regular /usr/lib directory for PIL
if platform?("ubuntu") and node[:languages][:ruby][:host_cpu] == "x86_64"
  ["libjpeg.so", "libz.so"].each do |lib|
    link "/usr/lib/#{lib}" do
      to "/usr/lib/x86_64-linux-gnu/#{lib}"
      owner "root"
      group "root"
    end
  end
end
