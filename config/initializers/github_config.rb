GITHUB_CONFIG = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(Rails.root.join("config", "github_credentials.yml")))