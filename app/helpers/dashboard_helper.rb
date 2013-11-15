module DashboardHelper
  def issue_labels(issue)
    label_names = []
    if issue.labels
      issue.labels.each do |label|
        label_names << label.name.gsub(' ','_')
      end
    end
    label_names.sort.join(' ')
  end

  def issue_link(repository, issue)
    "https://github.com/#{GITHUB_CONFIG[:org]}/#{repository.name}/issues/#{issue.number}"
  end
end