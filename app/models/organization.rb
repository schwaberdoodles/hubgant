class Organization
  @client = Github::Client.new.connection

  class << self
    def repositories
      @client.organization_repositories(GITHUB_CONFIG[:org])
    end

    def repository_names
      names = []
      repositories.each do |r|
        names << r.name
      end
      names
    end

    def milestones
      milestones = []
      repositories.each do |r|
        repo_milestones = @client.list_milestones("#{GITHUB_CONFIG[:org]}/#{r.name}")
        milestones += repo_milestones
      end
      milestones
    end

    def issues
      issues = []
      repositories.each do |r|
        issues += @client.list_issues("#{GITHUB_CONFIG[:org]}/#{r.name}")
      end
      issues
    end

  end
end
