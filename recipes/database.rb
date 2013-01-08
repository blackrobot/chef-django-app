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

node['app']['sites'].values.each do |site|
  mysql_database site['database']['name'] do
    connection db_conn
    action :create
  end

  if site['database'].has_key? 'user'
    mysql_database_user site['database']['user'] do
      connection db_conn
      database_name node['database']['name']
      host '%'
      privileges [:all]
      password node['database']['password']
      action [:create, :grant]
    end
  end
end

