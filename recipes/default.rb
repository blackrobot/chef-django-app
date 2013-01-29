#
# Cookbook Name:: django-app
# Recipe:: default
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_recipe "django-app::nginx"
include_recipe "django-app::database"
include_recipe "django-app::python"
include_recipe "django-app::django"
include_recipe "django-app::logrotate"
