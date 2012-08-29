include_recipe "mysql::server"
include_recipe "java::sun"
include_recipe "apt"

class Chef::Resource::Template
  include Opsview
end

directory "/var/cache/local/preseeding" do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

template "/var/cache/local/preseeding/opsview.seed" do
  source "opsview.seed.erb"
  owner "root"
  group "root"
  mode "0600"
  variables({:password => node['mysql']['server_root_password']})
end

execute "preseed opsview" do
  command "debconf-set-selections /var/cache/local/preseeding/opsview.seed"
  action :run
end

apt_repository "opsview" do
  if node[:opsview][:version] == 3
    uri "http://downloads.opsera.com/opsview-community/latest/apt"
  else
    uri "http://downloads.opsview.com/opsview-core/latest/apt"
  end
  if node["platform_version"][0] == ?6
    distribution "squeeze"
  elsif node["platform_version"][0] == ?5
    distribution "lenny"
  end
  components ["main"]
  keyserver "subkeys.pgp.net"
  key "77CB2CF6"
  action :add
  notifies :run, "execute[apt-get update]", :immediately
end

package "libltdl3" do
  action :install
  only_if do
    node["platform_version"][0] == ?5
  end
end

["opsview", "base-files"].each do |p|
  package p do
    action :install  
  end
end

service "opsview" do
  action :nothing
end

service "opsview-web" do
  action :nothing
end

if node[:opsview][:apache_proxy]
  include_recipe "apache2"
  include_recipe "apache2::mod_proxy"
  include_recipe "apache2::mod_proxy_http"

  source = "/usr/local/nagios/installer/apache_proxy.conf"
  target = "/etc/apache2/sites-available/opsview"
  
  execute "copy opsview proxy site" do
    command "cp #{source} #{target}"
    creates target
  end

  # Disable the default site
  apache_site "default" do
    enable false
  end

  apache_site "opsview" do
    enable true
  end
end

if !node[:opsview][:local_mysql]
  # Configure MySQL
  mysql_cmd = "/usr/local/nagios/bin/db_mysql -t | "
  mysql_cmd += "mysql -H #{node[:opsview][:mysql_host]} " 
  mysql_cmd += "-U #{node[:opsview][:mysql_user]} "
  mysql_cmd += "-P #{node[:opsview][:mysql_pwd]}"

  execute "opsview-sql" do
    command mysql_cmd
    not_if { node.attribute?("mysql_initialized") }
    notifies :create, "ruby_block[mysql_initialized_flag]", :immediately
  end

  ruby_block "mysql_initialized_flag" do
    block do
      node.set['mysql_initialized'] = true
      node.save
    end
    action :nothing
  end
end
