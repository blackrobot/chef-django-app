#
# Cookbook Name:: django-application
# Recipe:: database
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

db_conn = {
    :host => "localhost",
    :username => "root",
    :password => node['mysql']['server_root_password']
}

node['app']['sites'].each do |site|
  mysql_database site['database']['name'] do
    connection db_conn
    action :create
  end

  if site['database'].has_key? 'user'
    mysql_database_user site['database']['user'] do
      connection db_conn
      password node['database']['password']
      action :create
    end

    mysql_database_user site['database']['user'] do
      connection db_conn
      database_name node['database']['name']
      password node['database']['password']
      host db_conn['host']
      privileges [:all]
      action :grant
    end
  end
end

