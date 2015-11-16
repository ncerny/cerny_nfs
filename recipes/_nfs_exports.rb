#
# Cookbook Name:: cerny_nfs
# Recipe:: _nfs_exports
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

directory '/etc/exports.d'

file '/etc/exports' do
  case node['fqdn']
  when 'ceph03.cerny.cc' then
    content '/exports/nfs/iso 172.16.200.21(rw,sync,no_root_squash,fsid=2) 172.16.200.22(rw,sync,no_root_squash,fsid=2)'
  else
    content '/exports/nfs/vmware 172.16.200.21(rw,sync,no_root_squash,fsid=1) 172.16.200.22(rw,sync,no_root_squash,fsid=1)'
  end
  notifies :run, 'execute[exportfs -ra]', :delayed
end


execute 'exportfs -ra' do
  action :nothing
  only_if 'systemctl status nfs-server'
end
