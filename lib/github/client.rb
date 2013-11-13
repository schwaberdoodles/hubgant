require 'octokit'
require 'csv'
require 'date'

module Github
  class Client

    attr_reader :connection

    def initialize
      @connection = Octokit::Client.new login: GITHUB_CONFIG[:login], password: GITHUB_CONFIG[:password]
    end

  end
end