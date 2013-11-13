require 'octokit'
require 'csv'
require 'date'

class GitHubProjectSummarizer

  USERNAME="rljohnsn" 	# github username
  PASSWORD="xfactor12"	# github password
  USER="8x8Cloud"	# github organization
  TIMEZONE_OFFSET="-8"

  def initialize
    @client = connect(USERNAME,PASSWORD)
  end

  def connect(username,password)
    client = Octokit::Client.new(:login => username, :password => password)
    Octokit.auto_paginate = true
    client
  end

  def projects
    ['zerigocloud',
     'zerigocommon',
     'zerigoevents',
     'zerigomain',
     'zerigomanage',
     'zerigomonitor',
     'zerigons',
     'zerigoops',
     'zerigovdi',
     'zerigovps',
     'zerigopartner',
     'PowerShellCustomizers',
     'vBroker-2.0',
     'vAutomate'
    ]
  end
=begin
  # test repos
  def projects
    ['superrepo',
     'submodule01',
     'submodule02'
    ]
  end
=end

  # http://flatuicolors.com/#
  # alizarin      #e74c3c
  # pumpkin       #d35400
  # orange        #f39c12
  # sun flower    #f1c40f
  # silver        #bdc3c7
  # amethyst      #9b59b6
  # peter river   #3498db
  # carrot        #e67e22
  # emerald       #2ecc71
  # asbestos      #7f8c8d
  # clouds        #ecf0f1
  # midnight blue #2c3e50
  # pomegranate   #c0392b
  def labels
    [ {:name => 'Blocker Priority',   :color => 'e74c3c', :legacy => ''},  # :legacy string used to match deprecated labels
      {:name => 'Critical Priority',  :color => 'd35400', :legacy => ''},
      {:name => 'High Priority',      :color => 'f39c12', :legacy => ''},
      {:name => 'Med Priority',       :color => 'f1c40f', :legacy => ''},
      {:name => 'Low Priority',       :color => 'bdc3c7', :legacy => 'LP Low'},
      {:name => 'Type Question',      :color => '9b59b6', :legacy => 'question'},
      {:name => 'Type Specification', :color => '3498db', :legacy => ''},
      {:name => 'Type Bug',           :color => 'e67e22', :legacy => 'bug duplicate blocking defect blocking issue cannot verify or reproduce for verify Invalid'},
      {:name => 'Type New Feature',   :color => '2ecc71', :legacy => 'enhancement'},
      {:name => 'Client SoftBank',    :color => 'ecf0f1', :legacy => ''},
      {:name => 'Client CoSentry',    :color => '2c3e50', :legacy => ''},
      {:name => 'Client Zerigo',      :color => 'c0392b', :legacy => ''},
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

  def get_all_org_labels
    puts "Downloading all #{USER} issue labels"
    csv_output = CSV.new(File.open(File.dirname(__FILE__) + "/#{USER}-current_labels.csv", 'w'))
    repos = @client.organization_repositories("#{USER}")
    repos.each do |repo|
      puts "Processing #{repo.name}"
      label_list = []
      old_labels = @client.labels("#{USER}/#{repo.name}")
      # skip repo if it has no labels
      next if old_labels.length == 0
      old_labels.each do |old_label|
        label_list << "#{old_label.name}"
      end
      csv_output << [repo.name] + label_list.sort
    end

  end

  def add_labels
    projects.each do |project|
      # collect existing labels into a single string
      old_labels = @client.labels("#{USER}/#{project}")
      existing_labels = ""
      old_labels.each do |old_label|
        existing_labels << old_label.name
      end
      labels.each do |label|
        #if the label already exists, skip it
        next if existing_labels.include? label[:name]
        puts "Adding new #{label[:name]} label to #{project}"
        @client.add_label("#{USER}/#{project}", "#{label[:name]}", "#{label[:color]}")
      end
    end
  end

  def update_labels
    projects.each do |project|
      labels.each do |label|
        #puts "#{label[:name]} is #{label[:color]}"
        @client.update_label("#{USER}/#{project}", "#{label[:name]}", {:color => "#{label[:color]}"})
      end
    end
  end

  def fix_labels
    projects.each do |project|
      old_labels = @client.labels("#{USER}/#{project}")
      old_labels.each do |old_label|
        labels.each do |new_label|
          break if old_label.name === new_label[:name]
          if new_label[:legacy].downcase.include? "#{old_label.name}".downcase
            puts "Project: #{project} found label #{old_label.name} in \"#{new_label[:name]}\" label legacy strings \"#{new_label[:legacy]}\""
            # TODO: should iterate over issues and update issues with new labels, then delete legacy labels.
#          else
#            puts "#{old_label.name} NOT found in #{new_label[:name]} legacy strings #{new_label[:legacy]}"
          end
        end
        #@client.update_label("#{USER}/#{project}", "#{label[:name]}", {:color => "#{label[:color]}"})
      end
    end
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
end

summarizer = GitHubProjectSummarizer.new
#summarizer.milestones
#summarizer.issues_csv
#summarizer.add_labels        # DONE
#summarizer.update_labels     # DONE
#summarizer.fix_labels        # NOT DONE
summarizer.get_all_org_labels # DONE



