

package_url = 'http://apache.mirror.uber.com.au/jmeter/binaries/apache-jmeter-2.9.tgz'
package_filename = "#{Chef::Config['file_cache_path']}/#{File.basename(package_url)}"
remote_file package_filename do
  source package_url
  mode '0600'
  owner node['jenkins']['user']
  group node['jenkins']['group']
  action :create_if_missing
end

bash "extract jmeter" do
  cwd "/opt"
  code "tar xzf #{package_filename}"
  creates "/opt/apache-jmeter-2.9"
end
