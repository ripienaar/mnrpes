#!/usr/bin/env ruby

require 'mnrpes'
require 'optparse'

pidfile = nil
configfile = nil
checks = nil

opt = OptionParser.new

opt.on("--config [CONFiG]", "-c", "MCollective config file") do |v|
  configfile = v
end

opt.on("--pid [PIDFILE]", "-p", "PID file to write when daemonized") do |v|
  pidfile = v
end

opt.on("--checks [CHECKS]", "File with schedule of checks") do |v|
  checks = v
end

opt.parse!

abort("Checks file %s does not exist" % checks) unless File.exist?(checks)

mnrpes = MNRPES.new(configfile)

if mnrpes.config.daemonize
  mnrpes.daemonize(pidfile) do
    mnrpes.scheduler(checks).join
  end
else
  MNRPES::Log.info("Starting in the foreground")
  mnrpes.scheduler(checks).join
end
