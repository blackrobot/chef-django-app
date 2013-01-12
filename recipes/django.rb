#
# Cookbook Name:: django-application
# Recipe:: django
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

base_dir = node['app']['base']
envs_dir = "#{base_dir}/envs"

u = data_bag_item(node['app']['data_bag_name'], node['app']['user_id'])
app_user = u['username'] || u['id']
deploy_user = u['deploy_user'] || app_user
deploy_group = u['deploy_group'] || app_user
user_home = u['home'] || "/home/#{app_user}"

rsa_key = u['deploy_key']
git_wrapper = "#{base_dir}/deploy_ssh"


# Install virtualenvwrapper
python_pip "virtualenvwrapper" do
  action :install
end

# Create the WORKON_HOME directory
directory envs_dir do
  owner app_user
  group deploy_group
  mode 0755
  recursive true
end

if rsa_key
  # Upload the deploy key
  file "#{base_dir}/deploy_rsa" do
    content rsa_key
    owner app_user
    group deploy_group
    mode 0600
    action :create_if_missing
  end

  # Create the SSH wrapper
  template git_wrapper do
    source "deploy_ssh.erb"
    owner app_user
    group deploy_group
    mode 0550
    variables :base_dir => base_dir
    action :create_if_missing
  end
end


# Add the virtualenvwrapper vars to the bash profile
venv_script = "/usr/local/bin/virtualenvwrapper.sh"
usr_profile = "#{user_home}/.profile"

template "#{user_home}/.profile" do
  source "profile.erb"
  owner app_user
  group app_user
  mode 0644
  variables({
    :rsa_key => rsa_key,
    :git_wrapper_path => git_wrapper,
    :envs_dir => envs_dir,
    :venv_wrapper_path => venv_script
  })
end

bash "virtualenvwrapper" do
  code "su #{app_user} -l -c 'source #{usr_profile}'"
  action :run
end

# Create each of the sites
node['app']['sites'].each do |site|
  site_name = site['name']
  proj_dir = "#{base_dir}/#{site_name}"
  env_dir = "#{proj_dir}/env"
  app_dir = "#{proj_dir}/app"

  # Create the project dir
  directory proj_dir do
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

    if rsa_key
      ssh_wrapper "#{base_dir}/deploy_ssh"
    end
  end

  # Create all of the directories
  %w{ log log/nginx pid public public/static public/media }.each do |dir|
    directory "#{proj_dir}/#{dir}" do
      owner deploy_user
      group deploy_group
      mode 0770
      recursive true
    end
  end

  # Create the virtual environment
  bash "mkvirtualenv" do
    cwd user_home
    user app_user
    group deploy_group
    action :run
    code "source #{venv_script} && mkvirtualenv #{site_name}"
    environment({
      'HOME' => user_home,
      'WORKON_HOME' => envs_dir
    })
    creates "#{envs_dir}/#{site_name}"
  end

  # Create a symlink within our project
  link env_dir do
    to "#{envs_dir}/#{site_name}"
  end

  # Install the pip requirements
  bash "pip_requirements" do
    cwd app_dir
    user app_user
    group deploy_group
    action :run
    code <<-EOH
      #{env_dir}/bin/pip install -r #{app_dir}/#{site[:django][:requirements]}
    EOH
  end

  # Link the settings file
  link "#{app_dir}/#{site[:django][:settings][:link]}" do
    to "#{app_dir}/#{site[:django][:settings][:target]}"
  end

  # Setup supervisor
  link "#{node[:supervisor][:dir]}/#{site[:supervisor].split('/').last}" do
    to "#{app_dir}/#{site[:supervisor]}"
  end
end

# Reload supervisor configs
execute "supervisorctl update" do
  user "root"
end

# Restart nginx
service "nginx" do
  action :restart
end
