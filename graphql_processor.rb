# frozen_string_literal: true

require_relative './github/client'
require 'json'

module Github
  class GraphQLProcessor
    def initialize(client, org:)
      @client = client
      @org = org
    end

    def get_project(number)
      query = <<~GRAPHQL
        query($org: String!, $number: Int!){
          organization(login: $org) {
            projectV2(number: $number) {
              id
              title
              #
            }
          }
        }
      GRAPHQL

      result = @client.query_graphql(query, { org: @org, number: number })
      puts '###########'
      puts result
      puts '###########'
      edges = result.dig('data', 'viewer', 'organization', 'projectsV2', 'edges') || []
      edges.map { |e| e['node'].slice('number', 'title') }
    end

    def get_project_issues(project_number)
      query = <<~GRAPHQL
        query($org: String!, $projectNumber: Int!) {
          organization(login: $org) {
            projectV2(number: $projectNumber) {
              title
              items(first: 100) {
                nodes {
                  content {
                    ... on Issue {
                      title
                      url
                      number
                      state
                      createdAt
                      assignees(first: 5) {
                        nodes {
                          login
                        }
                      }
                    }
                  }
                  sprint: fieldValueByName(name: "Sprint") {
                    ... on ProjectV2ItemFieldDateValue {
                      date
                    }
                  }
                  points: fieldValueByName(name: "Points") {
                    ... on ProjectV2ItemFieldNumberValue {
                      number
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      items = []

      result = @client.query_graphql(query, {
                                       org: @org,
                                       projectNumber: project_number
                                     })

      nodes = result.dig('data', 'organization', 'projectV2', 'items', 'nodes') || []
      items.concat(nodes)

      items.sort_by { |i| i.dig('sprint', 'date') || '' }
    end

    def print_project_issues(project_number)
      get_project_issues(project_number).each do |item|
        title = item.dig('content', 'title')
        number = item.dig('content', 'number')
        sprint = item.dig('sprint', 'date')
        points = item.dig('points', 'number')
        puts "#{title} ##{number} — Sprint: #{sprint} — Points: #{points}"
      end
    end
  end
end

# We want to extend the API to return information about projects. Specifically,
# f you look at [this repo](https://github.com/orgs/interview-container/),
#  you’ll see [there is one project](https://github.com/orgs/interview-container/projects/1/),
#  and when an issue is added to a project, users can assign a Sprint Date and a Points value.

client = Github::Client.new(ENV['TOKEN'], ARGV[0])
processor = Github::GraphQLProcessor.new(client, org: ARGV[1])

processor.print_project_issues(ARGV[2].to_i)
