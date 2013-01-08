#
# Cookbook Name:: django-application
# Recipe:: nginx
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

node['app']['sites'].each do |site_name, site_conf|
  link "#{node[:nginx][:dir]}/sites-enabled/#{site_conf[:nginx].split('/').last}" do
    to "#{node[:app][:base]}/#{site_name}/app/#{site_conf[:nginx]}"
  end
end

service "nginx" do
  action :restart, :enable
end
