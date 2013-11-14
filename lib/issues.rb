require 'octokit'
require 'csv'
require 'date'

class GitHubProjectSummarizer

  USERNAME="rljohnsn" 	# github username
  PASSWORD="solar10"	# github password
  ORG="8x8Cloud"	# github organization
  TIMEZONE_OFFSET="-8"

  def initialize
    @client = connect(USERNAME,PASSWORD)
    if ORG.include? USERNAME
      @repos  = @client.repositories
    else
      @repos  = @client.organization_repositories("#{ORG}")
    end

  end

  def connect(username,password)
    client = Octokit::Client.new(:login => username, :password => password)
    Octokit.auto_paginate = true
    client
  end

=begin
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
=end

  # test repos
  def projects
    ['superrepo',
     'submodule01',
     'submodule02'
    ]
  end

  # http://flatuicolors.com/#
  # alizarin      #e74c3c blocker
  # pumpkin       #d35400 critical
  # orange        #f39c12 high
  # sun flower    #f1c40f med
  # silver        #bdc3c7 low
  # amethyst      #9b59b6 question
  # peter river   #3498db specification
  # carrot        #e67e22 bug
  # emerald       #2ecc71 new feature
  # asbestos      #7f8c8d abandon
  # clouds        #ecf0f1 softbank
  # midnight blue #2c3e50 cosentry
  # pomegranate   #c0392b zerigo
  # turquise      #1abc9c
  # wet asphalt   #34495e
  # green sea     #16a085 in progress
  # nephritis     #27ae60 resolved
  # belize hole   #2980b9
  # wisteria      #8e44ad re opened
  # concrete      #95a5a6
  def labels
    [ {:name => 'Blocker Priority',     :color => 'e74c3c', :legacy => ''},  # :legacy string used to match deprecated labels
      {:name => 'Critical Priority',    :color => 'd35400', :legacy => ''},
      {:name => 'High Priority',        :color => 'f39c12', :legacy => 'high hot'},
      {:name => 'Med Priority',         :color => 'f1c40f', :legacy => 'medium priority med'},
      {:name => 'Low Priority',         :color => 'bdc3c7', :legacy => 'LP Low'},
      {:name => 'Type Bug',             :color => 'e67e22', :legacy => 'bug blocking defect blocking issue'},
      {:name => 'Type Epic',            :color => '34495e', :legacy => ''},
      {:name => 'Type New Feature',     :color => '2ecc71', :legacy => 'enhancement feature request design requirement issue requirements issue'},
      {:name => 'Type Question',        :color => '9b59b6', :legacy => 'question'},
      {:name => 'Type Specification',   :color => '3498db', :legacy => 'requirement rejected requirement valid requirement accepted'},
      {:name => 'Type Story',           :color => '8e44ad', :legacy => ''},
      {:name => 'Resolution Fixed',     :color => '1abc9c', :legacy => 'for verify for verification'},
      {:name => 'Resolution Duplicate', :color => '95a5a6', :legacy => 'duplicate'},
      {:name => 'Resolution Abandon',   :color => '7f8c8d', :legacy => 'invalid wontfix cannot verify or reproduce requirement rejected wrong project'},
      {:name => 'Status In Progress',   :color => '16a085', :legacy => ''},
      {:name => 'Status Resolved',      :color => '27ae60', :legacy => ''},
      {:name => 'Status Reopened',      :color => '8e44ad', :legacy => ''},
      {:name => 'Client SoftBank',      :color => 'ecf0f1', :legacy => 'SoftBank'},
      {:name => 'Client CoSentry',      :color => '2c3e50', :legacy => 'CoSentry'},
      {:name => 'Client Zerigo',        :color => 'c0392b', :legacy => 'Zerigo'},
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
        project.name,
        issue[:number],
        issue[:title],
        issue[:state],
        get_milestone(issue[:milestone]),
        issue[:created_at],
        issue[:updated_at],
        get_user(issue),
        get_assignee(issue),
        get_link(ORG,project,issue),
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

  def get_org_labels
    puts "Downloading all #{ORG} issue labels"
    csv_output = CSV.new(File.open(File.dirname(__FILE__) + "/#{ORG}-current_labels.csv", 'w'))
    @repos.each do |repo|
      puts "Processing #{repo.name}"
      label_list = []
      old_labels = @client.labels("#{ORG}/#{repo.name}")
      # skip repo if it has no labels
      next if old_labels.length == 0
      old_labels.each do |old_label|
        label_list << "#{old_label.name}"
      end
      csv_output << [repo.name] + label_list.sort
    end
  end

  def add_org_labels
    @repos.each do |repo|
      puts("Adding new labels to #{repo.name}")
      # collect existing labels into a single string
      if repo.permissions.admin && repo.has_issues
        old_labels = @client.labels("#{ORG}/#{repo.name}")
        existing_labels = ""
        old_labels.each do |old_label|
          existing_labels << old_label.name
        end
        labels.each do |label|
          #if the label already exists, skip it
          next if existing_labels.include? label[:name]
          #puts "Adding new #{label[:name]} label to #{repo.name}"
          @client.add_label("#{ORG}/#{repo.name}", "#{label[:name]}", "#{label[:color]}")
        end
      end
    end
  end

  def update_org_labels   #labels must exist
    @repos.each do |repo|
      if repo.permissions.admin && repo.has_issues
        labels.each do |label|
          #puts "#{label[:name]} is #{label[:color]}"
          @client.update_label("#{ORG}/#{repo.name}", "#{label[:name]}", {:color => "#{label[:color]}"})
        end
      end
    end
  end

  def sync_org_labels
    add_org_labels    #creates new entries if they exist
    update_org_labels #updates settings (colors)
  end


  def migrate_org_labels
    # sync all labels for all repos
    sync_org_labels
    # for all issues add corresponding new label for each matching legacy label
    @repos.each do |repo|
      puts("Processing issue labels for #{repo.name}")
      if repo.permissions.admin && repo.has_issues
        issues = @client.list_issues("#{ORG}/#{repo.name}") #, :state => "open")
          issues.each do |issue|
              current_labels = get_labels(issue).gsub('_',' ')
              issue.labels.each do |old_label|
                labels.each do |new_label|
                   #if the issue already has the new label skip
                   next if current_labels.include? new_label[:name]
                   if new_label[:legacy].downcase.include? old_label.name.downcase
                     puts("Adding #{new_label[:name]} to #{repo.name}/#{issue.title}")
                     @client.add_labels_to_an_issue("#{ORG}/#{repo.name}",issue.number,[new_label[:name]])
                   end
                end
              end
          end
      end
    end
    # remove legacy labels for all repos (automatically removes them from existing issues)

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
      milestones = @client.milestones("#{ORG}/#{project}")
      milestones.each do |milestone|
        puts milestone.id.to_s + " " + milestone.title
      end
    end
  end

  def issues_csv
    puts "loading issues and saving to issues.csv..."
    csv_output = CSV.new(File.open(File.dirname(__FILE__) + "/issues.csv", 'w'))
    csv_output << header_row
    total=0
    @repos.each do |repo|
      issues = @client.list_issues("#{ORG}/#{repo.name}", {:state => "open", :per_page => 200})
      total += issues.length
      puts("Processing #{repo.name} with #{issues.length} open issues")
      #issues = @client.list_issues("#{ORG}/#{repo.name}", :state => "closed")
      issues.each do |issue|
        csv_output << get_issue_row(repo,issue)
      end
    end
    puts("Exported total of #{total} open issues")
  end

  def issues_json
      all_issues = []
      projects.each do |project|
        issues = @client.list_issues("#{ORG}/#{project}", :state => "open")
        all_issues << issues
      end
      all_issues
    end
end

summarizer = GitHubProjectSummarizer.new
#summarizer.milestones
summarizer.issues_csv
#summarizer.get_org_labels        # DONE
#summarizer.add_org_labels        # DONE
#summarizer.update_org_labels     # DONE
#summarizer.sync_org_labels       # DONE
#summarizer.migrate_org_labels    # DONE
#summarizer.get_org_milestones    # NOT DONE
#summarizer.add_org_milestones    # NOT DONE
#summarizer.update_org_milestones # NOT DONE



