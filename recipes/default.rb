#
# Cookbook Name:: django_application
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_recipe "django-application::nginx"
include_recipe "django-application::app"
include_recipe "django-application::logrotate"
