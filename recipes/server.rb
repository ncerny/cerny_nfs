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

node['nfs']['port'].each do |_, port|
  firewalld_port "#{port}/tcp" do
    zone 'internal'
  end
  firewalld_port "#{port}/udp" do
    zone 'internal'
  end
end

execute 'firewall-cmd --runtime-to-permanent'
