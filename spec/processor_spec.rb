# frozen_string_literal: true

require 'spec_helper'
require_relative '../process'

RSpec.describe Github::Processor do
  let(:client) { Github::Client.new('fake_token', 'https://api.github.com/repos/paper-trail-gem/paper_trail') }
  let(:processor) { described_class.new(client) }

  describe '#issues' do
    it 'prints sorted open issues' do
      issues = [
        { 'title' => 'Issue 1', 'state' => 'open', 'created_at' => '2025-08-15', 'closed_at' => '2025-08-19' },
        { 'title' => 'Issue 2', 'state' => 'open', 'created_at' => '2025-09-16', 'closed_at' => '2025-08-18' }
      ]
      allow(client).to receive(:fetch_all).and_return(issues)

      expect { processor.issues(open: true) }.to output(/Issue 2.*Created at/).to_stdout
    end
    it 'prints sorted closed issues' do
      issues = [
        { 'title' => 'Issue 1', 'state' => 'closed', 'created_at' => '2025-08-15', 'closed_at' => '2025-08-19' },
        { 'title' => 'Issue 2', 'state' => 'closed', 'created_at' => '2025-09-16', 'closed_at' => '2025-08-18' }
      ]

      allow(client).to receive(:fetch_all).and_return(issues)
      expect { processor.issues(open: false) }.to output(/Issue 2.*Closed at/).to_stdout
    end

    it 'handles API errors gracefully' do
      allow(client).to receive(:fetch_all).and_raise(Github::Client::Error.new('fail', status: 500, url: 'url'))

      expect { processor.issues(open: false) }.to output(/GitHub API Error/).to_stderr
    end
  end
end
