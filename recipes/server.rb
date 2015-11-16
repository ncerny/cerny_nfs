#
# Cookbook Name:: cerny_nfs
# Recipe:: server
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
#
# rubocop:disable LineLength

include_recipe 'nfs::_common'
include_recipe 'nfs::_idmap'

service 'rpcbind' do
  action [:enable, :start]
end

# ****
# From NFS Cookbook
# ****
# Install server components for Debian
package 'nfs-kernel-server' if node['platform_family'] == 'debian'

# Configure nfs-server components
template node['nfs']['config']['server_template'] do
  source 'nfs.erb'
  mode 00644
  notifies :restart, "service[#{node['nfs']['service']['server']}]"
end

# RHEL7 has some extra requriements per
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Storage_Administration_Guide/nfs-serverconfig.html#s2-nfs-nfs-firewall-config
if node['platform_family'] == 'rhel' && node['platform_version'].to_f >= 7.0 && !node['platform'] == 'amazon'
  include_recipe 'sysctl::default'

  sysctl_param 'fs.nfs.nlm_tcpport' do
    value node['nfs']['port']['lockd']
  end

  sysctl_param 'fs.nfs.nlm_udpport' do
    value node['nfs']['port']['lockd']
  end
end

# Start nfs-server components
service node['nfs']['service']['server'] do
  action :nothing
  supports status: true
end
# ****
# END NFS Cookbook
# ****

include_recipe 'firewalld'

node['nfs']['port'].each do |_, port|
  firewalld_port "#{port}/tcp" do
    zone 'internal'
    notifies :reload, 'service[firewalld]', :delayed
  end
  firewalld_port "#{port}/udp" do
    zone 'internal'
    notifies :reload, 'service[firewalld]', :delayed
  end
  execute "firewall-cmd --zone=public --add-port=#{port}/tcp --add-port=#{port}/udp" do
    notifies :reload, 'service[firewalld]', :delayed
  end
end

nfs_export '/exports/nfs' do
  network '*'
  writeable false
  sync true
  options %w( no_root_squash no_all_squash fsid=0 )
end

nfs_export '/exports/nfs/iso' do
  network '*'
  writeable true
  sync true
  options %w( no_root_squash no_all_squash fsid=1 )
end

nfs_export '/exports/nfs/vmware' do
  network %w( 172.16.200.21 172.16.200.22 )
  writeable true
  sync true
  options %w( no_root_squash no_all_squash fsid=2 )
end

include_recipe 'cerny_nfs::_keepalived'
