# frozen_string_literal: true

require_relative './client'
require 'json'

module Github
  class Processor
    # This class is responsible for processing the response from the Github API.
    # It accepts a client object and stores it as an instance variable.
    # It has a method called `issues` that returns a list of issues from the Github API.
    def initialize(client)
      @client = client
    end

    def issues(open: true)
      # This method returns a list of issues from the Github API.
      # It accepts an optional argument called `open` that defaults to true.
      # If `open` is true, it returns only open issues.
      # If `open` is false, it returns only closed issues.
      # It makes a GET request to the Github API using the client object.
      # It returns the response from the Github API.

      state = open ? 'open' : 'closed'
      # Return a list of issues from the response, with each line showing the issue's title,
      # whether it is open or closed,
      # and the date the issue was closed if it is closed, or the date the issue was created if it is open.
      # the issues are sorted by the date they were closed or created, from newest to oldest.

      # response = @client.get("/issues?state=#{state}")
      path = "/issues?state=#{state}"

      begin
        all_items = @client.fetch_all(path)
        issues = all_items.reject { |item| item.key?('pull_request') }
        # # issues = JSON.parse(response.body)
        sorted_issues = issues.sort_by do |issue|
          if state == 'closed'
            issue['closed_at']
          else
            issue['created_at']
          end
        end.reverse

        sorted_issues.each do |issue|
          if issue['state'] == 'closed'
            puts "#{issue['title']} - #{issue['state']} - Closed at: #{issue['closed_at']}"
          else
            puts "#{issue['title']} - #{issue['state']} - Created at: #{issue['created_at']}"
          end
        end
      rescue Github::Client::Error => e
        warn "GitHub API Error (#{e.status}) on #{e.url}"
        warn "Response body: #{e.response_body}"
      end
    end
  end
end
