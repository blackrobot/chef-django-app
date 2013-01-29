#
# Cookbook Name:: django-app
# Recipe:: database
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

if node['mysql']
  mysql_conn = {
    :host => "localhost",
    :username => "root",
    :password => node['mysql']['server_root_password']
  }
end

if node['postgresql']
  postgresql_conn = {
    :host => "localhost",
    :port => node['postgresql']['config']['port'],
    :username => "postgres",
    :password => node['postgresql']['password']['postgres']
  }
end

node['app']['sites'].each do |site|

  if site['database']['type'] == "mysql"
    mysql_database site['database']['name'] do
      connection mysql_conn
      action :create
    end

    if site['database'].has_key? 'user'
      mysql_database_user site['database']['user'] do
        connection mysql_conn
        password node['database']['password']
        action :create
      end

      mysql_database_user site['database']['user'] do
        connection mysql_conn
        database_name node['database']['name']
        password node['database']['password']
        host mysql_conn['host']
        privileges [:all]
        action :grant
      end
    end

  elsif site['database']['type'] == "postgresql"
    postgresql_database site['database']['name'] do
      connection postgresql_conn
      owner postgresql_conn['username']
      encoding site['database']['encoding']
      template site['database']['template']
      action :create
    end
  end
end

