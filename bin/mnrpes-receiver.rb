#!/usr/bin/env ruby

require 'mnrpes'
require 'optparse'

pidfile = nil
configfile = nil

opt = OptionParser.new

opt.on("--config [CONFiG]", "-c", "MCollective config file") do |v|
  configfile = v
end

opt.on("--pid [PIDFILE]", "-p", "PID file to write when daemonized") do |v|
  pidfile = v
end

opt.parse!

mnrpes = MNRPES.new(configfile)

if mnrpes.config.daemonize
  mnrpes.daemonize(pidfile) do
    mnrpes.receiver.receive_and_submit
  end
else
  MNRPES::Log.info("Starting in the foreground")
  mnrpes.receiver.receive_and_submit
end
