#
# Cookbook Name:: django_application
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_recipe "django_application::nginx"
include_recipe "django_application::app"
include_recipe "django_application::logrotate"
