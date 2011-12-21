# Various ports allocated to opsview.

include_recipe 'firewall'

if node[:recipes].include?("opsview::server")
  firewall_rule "mysqld" do
    port 3306
    action :deny
    provider Chef::Provider::FirewallRuleUfw
  end

  if node[:opsview][:apache_proxy] 
    firewall_rule "opsview-perl" do
      port 3000
      action :deny
      provider Chef::Provider::FirewallRuleUfw
    end

    firewall_rule "http" do
      port 80
      action :allow
      provider Chef::Provider::FirewallRuleUfw
    end

    firewall_rule "https" do
      port 443
      action :allow
      provider Chef::Provider::FirewallRuleUfw      
    end
  end
end

opsview_server = search(:node, 'recipes:opsview\:\:server')

if !opsview_server.nil? && !opsview_server.empty?
  firewall_rule "nrpe" do
    port 5666
    action :deny
    provider Chef::Provider::FirewallRuleUfw
  end

  firewall_rule "nrpe-to-server" do
    port 5666
    source opsview_server[0][:ipaddress]
    action :allow
    provider Chef::Provider::FirewallRuleUfw
  end
end
