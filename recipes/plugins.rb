plugins =
  {
    'mailer' => '1.5',
    'external-monitor-job' => '1.1',
    'ldap' => '1.5',
    'pam-auth' => '1.1',
    'jacoco' => '1.0.13',
    'javadoc' => '1.1',
    'ant' => '1.2',
    'token-macro' => '1.7',
    'dashboard-view' => '2.7',
    'analysis-core' => '1.49',
    'pmd' => '3.34',
    'rebuild' => '1.19',
    'violations' => '0.7.11',
    'Exclusion' => '0.8',
    'subversion' => '1.50',
    'parameterized-trigger' => '2.18',
    'dry' => '2.34',
    'checkstyle' => '3.35',
    'findbugs' => '4.48',
    'analysis-collector' => '1.35',
    'build-flow-plugin' => '0.9',
    'javancss' => '1.1',
    'translation' => '1.10',
    'ssh-slaves' => '0.27',
    'claim' => '2.2',
    'ansicolor' => '0.3.1',
    'jdepend' => '1.2.3',
    'testng-plugin' => '1.2',
    'nested-view' => '1.10',
    'show-build-parameters' => '1.0',
    'build-timeout' => '1.11',
    'project-stats-plugin' => '0.4',
    'git-client' => '1.0.7',
    'git' => '1.4.0',
    'doclinks' => '0.5',
    'tmpcleaner' => '1.1',
    'emma' => '1.29',
    'port-allocator' => '1.5',
    'embeddable-build-status' => '1.4',
    'email-ext' => '2.30.2',
    'greenballs' => '1.12',
    'gravatar' => '1.1',
    'github-api' => '1.42',
    'github' => '1.6',
    'batch-task' => '1.17',
    'htmlpublisher' => '1.2'
  }

jenkins_cli "safe-restart" do
  private_key node['jenkins']['private_key'] if node['jenkins']['private_key']
  action :nothing
end

plugins.each_pair do |key, version|
  jenkins_plugin key do
    private_key node['jenkins']['private_key'] if node['jenkins']['private_key']
    url "http://updates.jenkins-ci.org/download/plugins/#{key}/#{version}/#{key}.hpi"
    version version
    action :update
    notifies :run, 'jenkins_cli[safe-restart]', :delayed
  end
end
