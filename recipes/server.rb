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

template node['nfs']['config']['server_template'] do
  cookbook 'nfs'
  source 'nfs.erb'
  mode 00644
  notifies :restart, 'service[nfs-server]'
end

include_recipe 'sysctl::default'

sysctl_param 'fs.nfs.nlm_tcpport' do
  value node['nfs']['port']['lockd']
end

sysctl_param 'fs.nfs.nlm_udpport' do
  value node['nfs']['port']['lockd']
end

service 'nfs-server' do
  action :nothing
  supports status: true
  only_if 'systemctl status nfs-server'
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

include_recipe 'cerny_nfs::_keepalived'
include_recipe 'cerny_nfs::_nfs_exports'
