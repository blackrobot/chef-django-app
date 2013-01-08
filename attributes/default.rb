#
# Cookbook Name:: django_application
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_attribute "nginx"
include_attribute "mysql"
include_attribute "supervisor"

default['app']['base'] = "/var/www"
default['app']['data_bag_name'] = "users"
default['app']['user_id'] = "deploy"

default['app']['sites'] = {
  "production" => {
    "revision" => "production",
    "django" => {
      "requirements" => "requirements.txt",
      "settings" => {
        "target" => "source/settings/production.py",
        "link" => "source/settings/local.py"
      }
    },
    "supervisor" => "deploy/supervisor/production.conf",
    "nginx" => "deploy/nginx/production.conf"
  }
}
