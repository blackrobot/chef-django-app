#
# Cookbook Name:: django-application
# Recipe:: django
#
# Copyright 2012, Blenderbox
#
# All rights reserved - Do Not Redistribute
#

include_attribute "supervisor"

base_dir = node['app']['base']
envs_dir = "#{base_dir}/envs"

u = data_bag_item(node['app']['data_bag_name'], node['app']['user_id'])
app_user = u['username'] || u['id']
app_group = u['deploy_group']
rsa_key = u['deploy_key']
user_home = u['home'] || "/home/#{app_user}"

# Install virtualenvwrapper
python_pip "virtualenvwrapper" do
  action :install
end

# Create the WORKON_HOME directory
directory envs_dir do
  owner app_user
  group app_group
  mode 0755
end

# Add the virtualenvwrapper vars to the bash profile
venv_script = "/usr/local/bin/virtualenvwrapper.sh"
usr_profile = "#{user_home}/.profile"
bash "virtualenvwrapper" do
  code <<-EOF
    echo "export WORKON_HOME='#{envs_dir}'" >> #{usr_profile}
    echo "source #{venv_script}" >> #{usr_profile}
    source #{usr_profile}
  EOF
  action :run
  not_if "grep -q WORKON_HOME #{usr_profile}"
end

# Create each of the sites
node['app']['sites'].each do |site_name, site_conf|
  proj_dir = "#{base_dir}/#{site_name}"
  env_dir = "#{proj_dir}/env"
  app_dir = "#{proj_dir}/app"

  # Clone the application
  application site_name do
    path app_dir
    owner app_user
    group app_group
    repository node['app']['repository']
    revision site_conf['revision']
    deploy_key rsa_key if rsa_key
  end

  # Create all of the directories
  %w{ "log" "pid" "public/static" "public/media" }.values.each do |dir|
    directory "#{proj_dir}/#{dir}" do
      owner app_user
      group app_group
      mode 0755
      recursive true
    end
  end

  # Create the virtual environment
  execute "mkvirtualenv" do
    cwd user_home
    user app_user
    group app_group
    action :run
    command "source #{venv_script} && mkvirtualenv #{site_name}"
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
  execute "pip_requirements" do
    cwd app_dir
    user app_user
    group app_group
    action :run
    command "#{env_dir}/bin/pip install -r #{site_conf[:django][:requirements]}"
  end

  # Link the settings file
  link "#{app_dir}/#{site_conf[:django][:settings][:link]}" do
    to "#{app_dir}/#{site_conf[:django][:settings][:target]}"
  end

  # Setup supervisor
  link "#{node[:supervisor][:dir]}/#{site_conf[:supervisor].split('/').last}" do
    to "#{app_dir}/#{site_conf[:supervisor]}"
  end
end

# Restart supervisor
execute "supervisorctl restart all" do
  user "root"
end
