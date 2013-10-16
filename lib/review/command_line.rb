require 'optparse'
require 'review'


module Review
  class CommandLine
    def execute(argv = nil)
      argv ||= ARGV
      options = get_options(argv)
      repo = options[:repo]
      review = Review.new(repo)
      review.run(options[:id], options[:incremental_report])
    end

    def get_options(argv)
      options = {
        :id => nil,
        :incremental_report => true,
      }

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: review someuser/somerepo [--id ID] [--[no-]incremental-report]"
        opts.on('-i', '--id [ID]') do |id|
          options[:id] = id
        end
        opts.on('--[no-]incremental-report') do |bool|
          options[:incremental_report] = bool
        end
      end

      parser.parse!(argv)

      # Get repo
      if argv.length != 1
        puts parser
        exit(1)
      else
        options[:repo] = argv.shift
      end

      options
    end
  end
end
