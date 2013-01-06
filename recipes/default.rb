#
# Cookbook Name:: django-application
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_recipe "django-application::nginx"
include_recipe "django-application::database"
include_recipe "django-application::python"
include_recipe "django-application::django"
include_recipe "django-application::logrotate"
