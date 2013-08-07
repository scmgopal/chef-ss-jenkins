git "#{node['jenkins']['base_dir']}/.rbenv" do
  repository 'https://github.com/sstephenson/rbenv.git'
  reference 'master'
  user node['jenkins']['user']
  group node['jenkins']['group']
  action :sync
end

directory "#{node['jenkins']['base_dir']}/.rbenv/plugins/" do
  owner node['jenkins']['user']
  group node['jenkins']['group']
end


git "#{node['jenkins']['base_dir']}/.rbenv/plugins/ruby-build" do
  repository 'https://github.com/sstephenson/ruby-build.git'
  reference 'master'
  user node['jenkins']['user']
  group node['jenkins']['group']
  action :sync
end

base_packages = %w{ tar bash curl git-core }
cruby_packages = %w{ build-essential bison openssl libreadline6 libreadline6-dev
        zlib1g zlib1g-dev libpq-dev libssl-dev libyaml-dev libsqlite3-0
        libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf
        libc6-dev ssl-cert subversion }
jruby_packages =  %w{ make g++ }

(base_packages + cruby_packages + jruby_packages).each do |pkg|
  package pkg
end

['1.9.3-p448', '1.9.3-p327', 'jruby-1.7.1', 'jruby-1.7.2', 'jruby-1.6.7.2'].each do |rubie|
  bash "ruby-build #{rubie}" do
    user node['jenkins']['user']
    group node['jenkins']['group']
    code <<CMD
export PATH="#{node['jenkins']['base_dir']}/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
rbenv install #{rubie}
CMD
    not_if { File.exist?("#{node['jenkins']['base_dir']}/.rbenv/versions/#{rubie}")}
    environment ({'HOME' => node['jenkins']['base_dir']})
  end
end
