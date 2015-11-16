#
# Cookbook Name:: cerny_nfs
# Recipe:: _keepalived
#
# Copyright 2015 Nathan Cerny
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Temporarily turn off selinux until I can figure out how to allow keepalived's
# notify script to call rbd successfully.
# rubocop:disable LineLength
file '/etc/selinux/config' do
  content <<-EOF
    # This file controls the state of SELinux on the system.
    # SELINUX= can take one of these three values:
    #     enforcing - SELinux security policy is enforced.
    #     permissive - SELinux prints warnings instead of enforcing.
    #     disabled - No SELinux policy is loaded.
    SELINUX=permissive
    # SELINUXTYPE= can take one of three two values:
    #     targeted - Targeted processes are protected,
    #     minimum - Modification of targeted policy. Only selected processes are protected.
    #     mls - Multi Level Security protection.
    SELINUXTYPE=targeted
  EOF
  user 'root'
  group 'root'
  mode '0644'
end

execute 'setenforce Permissive' do
  only_if 'getenforce | grep Enforcing'
end

directory '/var/log/keepalived'

include_recipe 'sysctl::default'

package 'keepalived'

sysctl_param 'net.ipv4.ip_nonlocal_bind' do
  value '1'
end

template '/etc/keepalived/keepalived.conf' do
  source 'keepalived.conf.erb'
  owner 'root'
  group 'root'
  mode '0750'
  action :create
  notifies :reload, 'service[keepalived]', :delayed
end

cookbook_file '/usr/local/bin/keepalived_notify.sh' do
  source 'keepalived_notify.sh'
  owner 'root'
  group 'root'
  mode '0750'
  action :create
end

firewalld_rich_rule 'keepalived_mcast' do
  zone 'internal'
  family 'ipv4'
  destination_address '224.0.0.18/32'
  firewall_action 'protocol value="ip" accept'
  action :add
end

service 'keepalived' do
  action [:start, :enable]
end
