#
# Cookbook Name:: django-application
# Recipe:: logrotate
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

package "logrotate"

base_dir = node['app']['base']
sub_dirs = node['app']['dirs']

node['app']['sites'].each do |site|
  site_dir = "#{base_dir}/#{site[:name]}"

  template "/etc/logrotate.d/#{site[:name]}" do
    source "logrotate.erb"
    mode 0440
    owner "root"
    group "root"
    backup false
    variables({
      "site_dir" => site_dir,
      "nginx_user" => node['nginx']['user'],
      "nginx_group" => node['nginx']['group']
    })
  end
end
