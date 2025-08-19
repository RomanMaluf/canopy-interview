# frozen_string_literal: true

require 'spec_helper'
require_relative '../client'
require 'webmock/rspec'

RSpec.describe Github::Client do
  let(:token) { 'fake_token' }
  let(:repo_url) { 'https://api.github.com/repos/example/repo' }
  let(:client) { described_class.new(token, repo_url) }

  describe '#get' do
    it 'sends a GET request with correct headers' do
      stub = stub_request(:get, "#{repo_url}/issues")
             .with(headers: {
                     'Authorization' => "Bearer #{token}",
                     'User-Agent' => 'Github Client',
                     'Accept' => 'application/vnd.github+json'
                   }).to_return(status: 200, body: '[]', headers: {})

      response = client.get('/issues')
      expect(response.code).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  describe '#fetch_all' do
    it 'fetches all paginated results' do
      first_page = [
        { 'id' => 1 },
        { 'id' => 2 }
      ]
      second_page = [
        { 'id' => 3 }
      ]

      stub_request(:get, "#{repo_url}/issues?state=closed&per_page=2")
        .to_return(
          status: 200,
          body: first_page.to_json,
          headers: { 'Link' => "<#{repo_url}/issues?state=closed&per_page=2&page=2>; rel=\"next\"" }
        )

      stub_request(:get, "#{repo_url}/issues?state=closed&per_page=2&page=2")
        .to_return(
          status: 200,
          body: second_page.to_json,
          headers: {}
        )

      all_results = client.fetch_all('/issues?state=closed', per_page: 2)
      expect(all_results.size).to eq(3)
      expect(all_results.map { |i| i['id'] }).to eq([1, 2, 3])
    end
  end

  describe '#fetch_all error handling' do
    it 'raises custom error on failure' do
      stub_request(:get, "#{repo_url}/fail?per_page=1")
        .to_return(status: 500, body: 'Internal Server Error')

      expect do
        client.fetch_all('/fail', per_page: 1)
      end.to raise_error(Github::Client::Error)
    end
  end
end
