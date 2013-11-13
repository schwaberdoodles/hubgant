require 'spec_helper'

describe Github::Client do
  before(:each) do
    @client = Github::Client.new
  end

  describe "configuration" do
    it "configures itself" do
      expect(GITHUB_CONFIG).to be_an_instance_of(HashWithIndifferentAccess)
    end

    it "has information inside the config hash" do
      expect(GITHUB_CONFIG.size).to be > 0
    end

    it "has a username in the config" do
      expect(GITHUB_CONFIG["login"]).to_not be_nil
    end
  end

  it "points to github" do
    expect(@client.connection.api_endpoint).to eql "https://api.github.com/"
  end

  it "connects to github" do
    expect(@client.connection.user).to_not raise_error
  end
end