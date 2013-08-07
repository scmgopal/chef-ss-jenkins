module SsJenkins
  def rbenv_based_command(command, options)
    cmd = <<CMD
#!/usr/bin/env bash

export HOME=#{node['jenkins']['base_dir']}

# Need to set JAVA_HOME so that certain tools (RjB) will compile
export JAVA_HOME=#{node['java']['java_home']}

# Set maven repository to be local so artifacts are
# re-downloaded on each run. This catches the scenario
# where repository config is incorrectly specified
export M2_REPO=`pwd`/.repo

# Set the local gem directories so that gems are
# re-downloaded on each run. This catches the scenario
# where repository config is incorrectly specified
export GEM_HOME=`pwd`/.gems
export GEM_PATH=`pwd`/.gems

export PATH="#{node['jenkins']['base_dir']}/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

update_bundler() {
  rbenv exec gem list | grep 'bundler' &> /dev/null
  if [ $? -gt 0 ]; then
    if [[ `rbenv version` = "jruby-1.6.7.2"* ]]; then
      (rbenv exec gem list | grep 'jruby-openssl') || rbenv exec gem install jruby-openssl --version 0.8.2 --clear-sources --source #{node['rubygems-repo']}
      (rbenv exec gem list | grep 'bundler') || rbenv exec gem install bundler --no-ri --no-rdoc --version 1.3.1 --clear-sources --source #{node['rubygems-repo']}
    else
      (rbenv exec gem list | grep 'bundler') || rbenv exec gem install bundler --no-ri --no-rdoc --version 1.3.4 --clear-sources --source #{node['rubygems-repo']}
    fi
  fi
  if [ "$1" = 'quiet' ]; then
    rbenv exec bundle install --deployment > /dev/null 2> /dev/null
  else
    rbenv exec bundle install --deployment
  fi
}

if [ -f Gemfile ]; then
  i="0"

  until (bundle check > /dev/null 2> /dev/null) || [ $i -gt 10 ]; do
    echo "Bundle update. Attempt: $i"
    update_bundler 'quiet'
    i=$[$i+1]
  done

  if !(bundle check > /dev/null 2> /dev/null); then
    echo "Last Bundle update attempt."
    update_bundler
  fi
fi
CMD
    cmd << "\n#{options[:pre_exec]}\n" if options[:pre_exec]
    options[:locks].each_with_index do |lock, i|
      lock_fd = 99 - i
      lockfile = "/var/lock/#{lock}"
      cmd << <<CMD
_lock_#{lock_fd}()             { flock -$1 #{lock_fd}; }
_no_more_locking_#{lock_fd}()  { _lock_#{lock_fd} u; _lock_#{lock_fd} xn && rm -f #{lockfile}; }
_prepare_locking_#{lock_fd}()  { eval "exec #{lock_fd}>\"#{lockfile}\""; trap _no_more_locking_#{lock_fd} EXIT; }

_prepare_locking_#{lock_fd}

exlock_now_#{lock_fd}()        { _lock_#{lock_fd} xn; }  # obtain an exclusive lock immediately or fail
exlock_#{lock_fd}()            { _lock_#{lock_fd} x; }   # obtain an exclusive lock
shlock_#{lock_fd}()            { _lock_#{lock_fd} s; }   # obtain a shared lock
unlock_#{lock_fd}()            { _lock_#{lock_fd} u; }   # drop a lock

exlock_#{lock_fd}

CMD
    end if options[:locks]

    cmd << "xvfb-run -a rbenv exec bundle exec #{command}\n"
  end

  def buildr_command(targets, options = {})
    rbenv_based_command("buildr #{targets.join(' ')}", options)
  end

  def rake_command(targets, options = {})
    rbenv_based_command("rake #{targets.join(' ')}", options)
  end

  def generate_env_parameters_command()
    <<CMD
#!/usr/bin/env bash

export GIT_REVISION=`git rev-parse HEAD`
echo "GIT_REVISION=$GIT_REVISION" > parameters.txt
export PRODUCT_VERSION=`git rev-parse --short HEAD`
echo "PRODUCT_VERSION=${PRODUCT_VERSION}-${BUILD_NUMBER}" >> parameters.txt
CMD
  end

  def glassfish_deploy_command(domain, product, url, environment, options = {})
    check_environment(environment)
    rbenv_based_command("knife glassfish deploy --chef-environment #{environment} --domain #{domain} --deployable #{product} --url #{url} --version $PRODUCT_VERSION --system-user buildbot --system-private-key #{node['jenkins']['base_dir']}/.ssh/buildbot.pem --server-url #{Chef::Config[:chef_server_url]} --user buildbot --key #{node['jenkins']['base_dir']}/.ssh/buildbot.pem", options)
  end

  def application_deploy_command(application, environment, options = {})
    check_environment(environment)
    rbenv_based_command("knife application deploy --chef-environment #{environment} --application #{application} --version $PRODUCT_VERSION --winrm-user Administrator --winrm-password 'HP1nvent!' --ssh-user buildbot --ssh-private-key #{node['jenkins']['base_dir']}/.ssh/buildbot.pem --server-url #{Chef::Config[:chef_server_url]} --user buildbot --key #{node['jenkins']['base_dir']}/.ssh/buildbot.pem", options)
  end

  def check_environment(environment)
    raise "Invalid environment #{environment}" unless ["development", "ci", "uat", "training", "staging", "production"].include?(environment)
  end

  def base_config_xml
    ::Chef::JenkinsConfigXML.new
  end

  def product_job_parameters
    {'PRODUCT_VERSION' => {'description' => 'The version of artifact to deploy'} }
  end

  def git_revision_parameters
    {'GIT_REVISION' => {'defaultValue' => 'master', 'description' => 'The git revision'}}
  end

  def standard_job_parameters
    product_job_parameters.merge(git_revision_parameters)
  end

  def selenium_job_parameters(site_url = nil)
    standard_job_parameters.merge(
      'BROWSER_KEY' => {'description' => 'The browser to use in test', 'choices' => ['chrome', 'firefox']},
      'SITE_URL' => {'description' => 'The url against which to run the selenium tests', 'defaultValue' => site_url}
    )
  end

  def glassfish_deploy_job(domain, product, url, environment, options = {})
    base_config_xml.
      parameters_definition_property(product_job_parameters).
      shell_builder(glassfish_deploy_command(domain, product, url, environment, options.merge(:locks => ["DEPLOY_LOCK_#{domain}"]))).
      extended_email_publisher('dse-iris-scm@stocksoftware.com.au')
  end

  def application_deploy_job(application, environment, options = {})
    base_config_xml.
      parameters_definition_property(product_job_parameters).
      shell_builder(application_deploy_command(application, environment, options.merge(:locks => ["DEPLOY_LOCK_#{application}"]))).
      extended_email_publisher('dse-iris-scm@stocksoftware.com.au')
  end

  def database_lock_config
    {:locks => ['CI_DATABASE_LOCK']}
  end

  def database_intensive_job(repository_name, buildr_tasks, options = {})
    config_xml(repository_name, options).
      shell_builder(buildr_command(buildr_tasks, database_lock_config))
  end

  def rake_database_intensive_job(repository_name, buildr_tasks, options = {})
    config_xml(repository_name, options).
      shell_builder(rake_command(buildr_tasks, database_lock_config))
  end

  def build_flow_jobs(jobs, project_prefix, repo, flow, options = {})
    jobs["#{project_prefix}_BuildFlow_Trigger"] =
      config_xml(repo, options).
        scm_trigger("H/5 * * * * ").
        blockBuildWhenDownstreamBuilding(true).
        shell_builder(generate_env_parameters_command()).
        extended_email_publisher('dse-iris-scm@stocksoftware.com.au').
        downstream_parameterized_build_trigger(["#{project_prefix}_BuildFlow"], 'parameters' => {'propertiesFile' => 'parameters.txt'})

    jobs["#{project_prefix}_BuildFlow"] =
      base_config_xml.
        add_build_flow(flow).
        parameters_definition_property(standard_job_parameters)
  end

end
