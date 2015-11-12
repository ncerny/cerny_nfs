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

include_recipe 'nfs::_common'
include_recipe 'nfs::_idmap'

service 'rpcbind' do
  action [:enable, :start]
end

include_recipe 'nfs::server'

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
end

nfs_export '/exports' do
  network '172.16.200.0/24'
  writeable false
  sync true
  options %w( no_root_squash no_all_squash fsid=0 )
end

nfs_export '/exports/iso' do
  network %w( 172.16.200.0/24 172.16.201.0/24 172.16.202.0/24 )
  writeable true
  sync true
  options %w( no_root_squash no_all_squash )
end

nfs_export '/exports/vcenter' do
  network %w( 172.16.201.21 172.16.201.22 172.16.202.21 172.16.202.22 )
  writeable true
  sync true
  options %w( no_root_squash no_all_squash )
end
