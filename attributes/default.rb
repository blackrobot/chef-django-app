#
# Cookbook Name:: django_application
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_attribute "virtualenvwrapper"
include_attribute "nginx"
include_attribute "mysql::server"
include_attribute "postgresql"
include_attribute "supervisor"

default['app']['base'] = "/var/www"
default['app']['data_bag_name'] = "users"
default['app']['user_id'] = "deploy"

default['app']['sites'] = []
