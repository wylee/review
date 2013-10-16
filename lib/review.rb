require 'octokit'
require 'set'
require 'review/diff'

# We're interested in *any* change to these files
INTERESTING_FILES = Set.new(['Gemfile', '.gemspec'])

# We're interested in changed lines that contain these words
INTERESTING_PATTERNS = [
  /(?!\b)(\/dev\/null|\.write|%x)\b/,
  /\b(raise|\.write|exec)\b/,
]

USER_AGENT = 'wylee/review'

module Review
  class Review
    def initialize(repo)
      @repo = repo
      @client = Octokit::Client.new(:user_agent => USER_AGENT)
    end

    # Review pull request(s) and report
    def run(id = nil, incremental_report = true)
      data = []
      if id
        pull_request = @client.pull_request(@repo, id)
        record = process_pull_request(pull_request)
        incremental_report ? report_one(record) : data.push(record)
      else
        pull_requests = @client.pull_requests(@repo)
        while pull_requests
          pull_requests.each do |pull_request|
            record = process_pull_request(pull_request)
            incremental_report ? report_one(record) : data.push(record)
          end
          next_rel = @client.last_response.rels[:next]
          pull_requests = next_rel ? next_rel.get.data : nil
        end
      end
      report(data) unless incremental_report
    end

    def process_pull_request(pull_request)
      return {
        :url => pull_request.rels[:html].href,
        :is_interesting => pull_request_is_interesting?(pull_request),
      }
    end

    def pull_request_is_interesting?(pull_request)
      data = pull_request.rels[:diff].get.data
      diff = Diff.new(data)

      diff.files.each do |file|
        if file.name =~ /^spec\//
          return false
        elsif INTERESTING_FILES.include?(file.name)
          return true
        elsif INTERESTING_FILES.include?(file.original_name)
          return true
        end

        file.lines.each do |line|
          INTERESTING_PATTERNS.each do |pattern|
            return true if line =~ pattern
          end
        end
      end

      false
    end

    def report(data)
      data.each {|record| report_one(record)}
    end

    def report_one(record)
      classification = "#{'Not ' if !record[:is_interesting]}Interesting"
      puts "#{record[:url]} - #{classification}"
    end
  end
end
