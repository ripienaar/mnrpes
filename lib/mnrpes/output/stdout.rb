class MNRPES
  class Output
    class Stdout
      def initialize
      end

      def process(data)
        raise "No data received" unless data

        puts data.inspect
      end
    end
  end
end
