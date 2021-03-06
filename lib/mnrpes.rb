require 'mcollective'
require 'mnrpes/receiver'
require 'mnrpes/scheduler'

class MNRPES
  Log = MCollective::Log

  attr_reader :config

  def initialize(configfile = nil)
    configure(configfile)
  end

  def receiver
    if @receiver
      @receiver
    else
      processor = @config.pluginconf.fetch("mnrpes.processors", "nagios")
      destination = @config.pluginconf.fetch("mnrpes.reply_queue", "/queue/mcollective.nagios_passive_results")

      @receiver = Receiver.new(processor.downcase, destination)
    end
  end

  def scheduler(checks)
    if @scheduler
      @scheduler
    else
      destination = @config.pluginconf.fetch("mnrpes.reply_queue", "/queue/mcollective.nagios_passive_results")
      @scheduler = Scheduler.new(destination, checks)
    end
  end

  def daemonize(pidfile=nil)
    MNRPES::Log.info("Starting in the background")

    require 'mcollective/unix_daemon'

    MCollective::UnixDaemon.daemonize do
      if pidfile
        File.open(pidfile, 'w') {|f| f.write(Process.pid) } rescue nil
      end

      begin
        yield
      ensure
        File.unlink(pidfile) if pidfile && File.exist?(pidfile)
      end
    end
  end

  def configure(configfile=nil)
    configfile = MCollective::Util.config_file_for_user unless configfile

    MCollective::Config.instance.loadconfig(configfile)
    MCollective::PluginManager["security_plugin"].initiated_by = :client

    @config = MCollective::Config.instance
  end
end
