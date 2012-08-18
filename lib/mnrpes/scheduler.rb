class MNRPES
  class Scheduler
    include MCollective::RPC

    def initialize(destination, checks)
      @destination = destination
      @jobs = []

      require 'rubygems'
      require 'rufus/scheduler'

      @scheduler = Rufus::Scheduler.start_new
      @nrpe = rpcclient("nrpe")
      @nrpe.reply_to = destination

      instance_eval(File.read(checks))
    end

    def nrpe(command, interval, filter=nil)
      options = {:first_in => "%ss" % rand(60),
                 :blocking => true}

      Log.info("Adding a job for %s every %s matching '%s', first in %s" % [command, interval, filter, options[:first_in]])

      @jobs << @scheduler.every(interval.to_s, options) do
        Log.info("Publishing request for %s with filter '%s'" % [command, filter])

        @nrpe.reset_filter
        @nrpe.filter = parse_filter(filter)
        @nrpe.runcommand(:command => command.to_s)
      end
    end

    def parse_filter(filter)
      new_filter = MCollective::Util.empty_filter

      return new_filter unless filter

      filter.split(" ").each do |filter|
        begin
          fact_parsed = MCollective::Util.parse_fact_string(filter)
          new_filter["fact"] << fact_parsed
        rescue
          new_filter["cf_class"] << filter
        end
      end

      new_filter
    end

    def join
      @scheduler.join
    end
  end
end
