#
# Cookbook Name:: django-app
# Recipe:: django
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_recipe "virtualenvwrapper"

restart_supervisor = false
restart_uwsgi = false

base_dir = node['app']['base']
envs_dir = ::File.join(base_dir, "envs")

u = data_bag_item(node['app']['data_bag_name'], node['app']['user_id'])
app_user = u['username'] || u['id']
deploy_user = u['deploy_user'] || app_user
deploy_group = u['deploy_group'] || app_user
user_home = u['home'] || "/home/#{app_user}"

# Add the deploy key if it exists
if u['deploy_key']
  git_ssh_wrapper "deploy" do
    owner app_user
    group deploy_group
    key u['deploy_key']
    path base_dir
    profile ::File.join(user_home, ".profile")
  end
end

# Create each of the sites
node['app']['sites'].each do |site|
  site_name = site['name']
  prj_dir = ::File.join(base_dir, site_name)
  env_dir = ::File.join(prj_dir, "env")
  app_dir = ::File.join(prj_dir, "app")

  # Create the project dir
  directory prj_dir do
    owner deploy_user
    group deploy_group
    mode 0770
    recursive true
  end

  # Clone the application
  git site_name do
    destination app_dir
    repository site['repository']
    reference site['reference'] || "master"

    user app_user
    group deploy_group

    action :sync

    if u['deploy_key']
      ssh_wrapper ::File.join(base_dir, "deploy_ssh")
    end
  end

  # Create all of the directories
  %w{ log log/nginx tmp public public/static public/media }.each do |dir|
    directory ::File.join(prj_dir, dir) do
      owner deploy_user
      group deploy_group
      mode 0770
      recursive true
    end
  end

  # Create the virtual env, and install the requirements
  virtualenvwrapper site_name do
    owner app_user
    group deploy_group
    requirements ::File.join(app_dir, site['django']['requirements'])
    action [:create, :install]
  end

  # Create a symlink within our project
  link env_dir do
    to ::File.join(envs_dir, site_name)
  end

  # Link the settings file
  link ::File.join(app_dir, site['django']['settings']['link']) do
    to ::File.join(app_dir, site['django']['settings']['target'])
  end

  # Collect static
  if site['django']['collectstatic']
    py_bin = ::File.join(env_dir, "bin", "python")
    manage_py = ::File.join(app_dir, "manage.py")
    execute "#{py_bin} #{manage_py} collectstatic --noinput" do
      action :run
    end
  end

  if site['supervisor']
    supervisor_link = ::File.join(node['supervisor']['dir'],
                                  site['supervisor'].split('/').last)
    # Setup supervisor
    link supervisor_link do
      to ::File.join(app_dir, site['supervisor'])
    end

    restart_supervisor = true

  elsif site['uwsgi']
    uwsgi ::File.join(app_dir, site['uwsgi']) do
      action :enable
    end

    restart_uwsgi = true

  end
end

# Reload supervisor and uwsgi configs
if restart_supervisor
  execute "supervisorctl update" do
    user "root"
  end
end

if restart_uwsgi
  service "uwsgi" do
    action :restart
  end
end

# Restart nginx
service "nginx" do
  action :restart
end
