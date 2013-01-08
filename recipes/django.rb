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
  recursive true
end

if rsa_key
  # Upload the deploy key
  file "#{base_dir}/deploy_rsa" do
    content rsa_key
    owner app_user
    group app_group
    mode 0600
  end

  # Create the SSH wrapper
  template "#{base_dir}/deploy_ssh" do
    source "deploy_ssh.erb"
    owner app_user
    group app_group
    mode 0550
    variables :base_dir => base_dir
  end
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
node['app']['sites'].each do |site|
  site_name = site['name']
  proj_dir = "#{base_dir}/#{site_name}"
  env_dir = "#{proj_dir}/env"
  app_dir = "#{proj_dir}/app"

  # Clone the application
  git site_name do
    destination app_dir
    repository site['repository']
    revision site['revision'] || "HEAD"

    user app_user
    group app_group

    if rsa_key
      ssh_wrapper "#{base_dir}/deploy_ssh"
    end
  end

  # Create all of the directories
  ["log", "pid", "public/static", "public/media"].each do |dir|
    directory "#{proj_dir}/#{dir}" do
      owner app_user
      group app_group
      mode 0755
      recursive true
    end
  end

  # Create the virtual environment
  bash "mkvirtualenv" do
    cwd user_home
    user app_user
    group app_group
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
  execute "pip_requirements" do
    cwd app_dir
    user app_user
    group app_group
    action :run
    command "#{env_dir}/bin/pip install -r #{site[:django][:requirements]}"
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

# Restart supervisor
execute "supervisorctl restart all" do
  user "root"
end
