require 'octokit'
require 'csv'
require 'date'

class GitHubProjectSummarizer

  USERNAME="" 	# github username
  PASSWORD=""	# github password
  USER="8x8Cloud"	# github organization
  TIMEZONE_OFFSET="-7"

  def initialize
    @client = connect(USERNAME,PASSWORD)
  end

  def connect(username,password)
    client = Octokit::Client.new(:login => username, :password => password)
    Octokit.auto_paginate = true
    client
  end

  def projects
    ['zerigovdi',
     'zerigomanage',
     'zerigocommon',
     'zerigovps',
     'zerigocloud',
     'zerigomonitor',
     'zerigomain',
     'zerigopartner',
     'zerigons',
     'PowerShellCustomizers',
     'vBroker-2.0'
    ]
  end

  def header_row
    [ 'project',
      'issue_number',
      'title',
      'state',
      'milestone',
      'created_at',
      'updated_at',
      'created_by',
      'owned_by',
      'link',
      'labels'
    ]
  end

  def get_issue_row(project,issue)
    row = [
        project,
        issue[:number],
        issue[:title],
        issue[:state],
        get_milestone(issue[:milestone]),
        issue[:created_at],
        issue[:updated_at],
        get_user(issue),
        get_assignee(issue),
        get_link(USER,project,issue),
        get_labels(issue)
    ]
  end

  def get_link(user,project,issue)
    "https://github.com/#{user}/#{project}/issues/#{issue.number}"
  end

  def get_milestone(milestone)
    if milestone
      return milestone.title
    end
    "none"
  end

  def get_labels(issue)
    label_names = []
    if issue.labels
      issue.labels.each do |label|
        label_names << label.name.gsub(' ','_')
      end
    end
    label_names.sort.join(' ')
  end

  def get_assignee(issue)
    owner = "nobody"
    if issue.assignee
      owner = issue.assignee[:login]
    end
    owner
  end

  def get_user(issue)
    user = "nobody"
    if issue.user
      user = issue.user[:login]
    end
    user
  end

  def milestones
    puts "loading milestones..."
    projects.each do |project|
      milestones = @client.milestones("#{USER}/#{project}")
      milestones.each do |milestone|
        puts milestone.id.to_s + " " + milestone.title
      end
    end
  end

  def issues_csv
    puts "loading issues and saving to issues.csv..."
    csv_output = CSV.new(File.open(File.dirname(__FILE__) + "/issues.csv", 'w'))
    csv_output << header_row
    projects.each do |project|
      issues = @client.list_issues("#{USER}/#{project}", :state => "open")
      #issues = @client.list_issues("#{USER}/#{project}", :state => "closed")
      issues.each do |issue|
        csv_output << get_issue_row(project,issue)
      end
    end
  end

  def issues_json
    all_issues = []
    projects.each do |project|
      issues = @client.list_issues("#{USER}/#{project}", :state => "open")
      all_issues << issues
    end
    all_issues
end

summarizer = GitHubProjectSummarizer.new
summarizer.milestones
summarizer.issues_csv
