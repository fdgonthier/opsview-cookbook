# Install client opsview package.

if platform?("debian") and !node[:recipes].include?("opsview::server")
  include_recipe "apt"
  
  apt_repository "opsview" do
    uri "http://downloads.opsera.com/opsview-community/latest/apt"
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
  
  package "opsview-agent" do
    action :install
  end
end

# Configure the local client to accept local connection only.
opsview_servers = search(:node, 'recipes:opsview\:\:server')  
allowed_hosts = opsview_servers.map { |item| item[:ipaddress] }.join(",")

service "opsview-agent" do
  action :nothing
end

template "/usr/local/nagios/etc/nrpe_local/allowed_hosts.cfg" do
  source "nrpe_allowed_hosts.erb"
  mode 0644
  owner "root"
  group "root"
  variables(:allowed_hosts => allowed_hosts)
  notifies :restart, resources(:service => "opsview-agent")
end

template "/usr/local/nagios/etc/nrpe_local/check_apt.cfg" do
  source "nrpe_check_apt.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, resources(:service => "opsview-agent")
end

template "/etc/sudoers.d/nrpe_sudoers" do
  source "nrpe_sudoers.erb"
  mode 0440
  owner "root"
  group "root"
end
