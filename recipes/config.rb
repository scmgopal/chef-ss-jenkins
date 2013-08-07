hudson_url = ::Chef::Jenkins.jenkins_server_url(node)
admin_email = node['jenkins']['config']['admin-email']
recipient_list = node['jenkins']['config']['admin-email']
list_id = node['jenkins']['server']['host']
smtp_host = Chef::Services.lookup(node, 'smtp')['host']

config_files = {
  'hudson.plugins.ansicolor.AnsiColorBuildWrapper' => {},
  'jenkins.model.JenkinsLocationConfiguration' =>  {'hudson_url' => hudson_url, 'admin_email' => admin_email},
  'com.cloudbees.jenkins.GitHubPushTrigger' => {},
  'hudson.maven.MavenModuleSet' => {},
  'hudson.model.UpdateCenter' => {},
  'hudson.plugins.emailext.ExtendedEmailPublisher' =>
    {
      'hudson_url' => "#{hudson_url}/",
      'admin_email' => admin_email,
      'list_id' => list_id
    },
  'hudson.plugins.git.GitTool' => {},
  'hudson.tasks.Ant' => {},
  'hudson.tasks.Maven' => {},
  'hudson.tasks.Shell' => {},
  'org.jenkinsci.plugins.mavenrepocleaner.MavenRepoCleanerProperty' => {},
  'hudson.triggers.SCMTrigger' => {},
  'hudson.tasks.Mailer' =>
    {
      'hudson_url' => hudson_url,
      'admin_email' => admin_email,
      'list_id' => list_id,
      'reply_to_address' => recipient_list,
      'smtp_host' => smtp_host
    },
  'hudson.scm.CVSSCM' => {},
  'hudson.scm.SubversionSCM' => {}
}

config_files.each_pair do |config_file, config|
  config.merge!('source' => "configs/#{config_file}.xml.erb")
  config.merge!('cookbook' => "ss-jenkins")
end

jenkins_config_set "config_set" do
  private_key node['jenkins']['private_key'] if node['jenkins']['private_key']
  configs config_files
end
