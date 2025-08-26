# frozen_string_literal: true

require 'httparty'

module Github
  class Client
    # CustomError class It is thrown when an error occurs with the API
    class Error < StandardError
      attr_reader :status, :url, :response_body

      def initialize(message, status: nil, url: nil, response_body: nil)
        super(message)
        @status = status
        @url = url
        @response_body = response_body
      end
    end

    # this class is responsible for making requests to the Github API
    # It accepts a personal access token and stores it as an instance variable.
    # It has a method called `get` that accepts a URL and returns the response
    # from the Github API

    def initialize(token, repo_url)
      # implement this method
      @token = token
      @repo_url = repo_url
    end

    def get(path_or_url)
      url = path_or_url.start_with?('http') ? path_or_url : full_url_for(path_or_url)
      HTTParty.get(url, headers: headers)
    end

    def fetch_all(path, per_page: 50)
      # this method fetch all available pages from the github headers['links']
      initial_path = "#{path}#{path.include?('?') ? '&' : '?'}per_page=#{per_page}"
      url = full_url_for(initial_path)
      results = []

      loop do
        response = get(url)

        unless response.success?
          raise Github::Client::Error.new(
            "GitHub API request failed with status #{response.code}",
            status: response.code,
            url: url,
            response_body: response.body
          )
        end

        data = JSON.parse(response.body)
        results.concat(data)

        url = extract_next_link(response.headers['link'])
        break unless url
      end

      results
    end

    def query_graphql(query, variables = {})
      response = HTTParty.post(
        @repo_url,
        headers: headers.merge('Content-Type' => 'application/json'),
        body: { query: query, variables: variables }.to_json
      )

      unless response.success?
        raise Error.new("GraphQL API error: #{response.code}", status: response.code, url: @repo_url,
                                                               response_body: response.body)
      end

      JSON.parse(response.body)
    end

    private

    def headers
      # this method returns the headers required to make requests to the Github API using a personal access token
      {
        'Authorization' => "Bearer #{@token}",
        'User-Agent' => 'Github Client',
        'Accept' => 'application/vnd.github+json'
      }
    end

    def full_url_for(path)
      @repo_url + path
    end

    def extract_next_link(link_header)
      return nil unless link_header

      links = link_header.split(',').map(&:strip)

      next_link = links.find { |link| link.include?('rel="next"') }
      return nil unless next_link

      next_link.match(/<([^>]+)>/)[1]
    end
  end
end
