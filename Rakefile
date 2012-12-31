# Rakefile to build a project using HUDSON

require 'rake/clean'

PROJ_NAME = "mnrpes"
PROJ_FILES = ["bin", "lib", "#{PROJ_NAME}.spec", "etc", "mnrpes-receiver.init", "mnrpes-scheduler.init"]
PROJ_DOC_TITLE = "MNRPES - MCollective based system to scale NRPE checks"
PROJ_VERSION = "0.1"
PROJ_RELEASE = "2"
PROJ_RPM_NAMES = [PROJ_NAME]

ENV["RPM_VERSION"] ? CURRENT_VERSION = ENV["RPM_VERSION"] : CURRENT_VERSION = PROJ_VERSION
ENV["BUILD_NUMBER"] ? CURRENT_RELEASE = ENV["BUILD_NUMBER"] : CURRENT_RELEASE = PROJ_RELEASE

CLEAN.include("pkg")

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def init
  FileUtils.mkdir("pkg") unless File.exist?("pkg")
end

desc "Create a tarball for this release"
task :archive => [:clean] do
  announce "Creating #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.tgz"

  FileUtils.mkdir_p("pkg/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")
  sh %{cp -R #{PROJ_FILES.join(' ')} pkg/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}}
  sh %{cd pkg && /bin/tar --exclude .svn -cvzf #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.tgz #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}}
end

desc "Creates a RPM"
task :rpm => [:archive] do
  announce("Building RPM for #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")

  sourcedir = `/bin/rpm --eval '%_sourcedir'`.chomp
  specsdir = `/bin/rpm --eval '%_specdir'`.chomp
  srpmsdir = `/bin/rpm --eval '%_srcrpmdir'`.chomp
  rpmdir = `/bin/rpm --eval '%_rpmdir'`.chomp
  lsbdistrel = `/usr/bin/lsb_release -r -s|/bin/cut -d . -f1`.chomp
  lsbdistro = `/usr/bin/lsb_release -i -s`.chomp

  case lsbdistro
    when 'CentOS'
      rpmdist = "el#{lsbdistrel}"
    else
      rpmdist = ""
  end

  sh %{cp pkg/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.tgz #{sourcedir}}
  sh %{cp #{PROJ_NAME}.spec #{specsdir}}

  sh %{cd #{specsdir} && rpmbuild -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist .#{rpmdist}' -ba #{PROJ_NAME}.spec}

  sh %{cp #{srpmsdir}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.#{rpmdist}.src.rpm pkg/}

  sh %{cp #{rpmdir}/*/#{PROJ_NAME}*-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.#{rpmdist}.*.rpm pkg/}
end
