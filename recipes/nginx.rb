#
# Cookbook Name:: django-app
# Recipe:: nginx
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

node['app']['sites'].each do |site|
  link "#{node[:nginx][:dir]}/sites-enabled/#{site[:nginx].split('/').last}" do
    to "#{node[:app][:base]}/#{site[:name]}/app/#{site[:nginx]}"
  end
end
