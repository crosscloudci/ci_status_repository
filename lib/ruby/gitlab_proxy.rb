require "gitlab"
require 'json'
require 'awesome_print'

def gitlab_client 
  Gitlab.configure do |config|
    config.endpoint = ENV["GITLAB_API"] # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
    # config.endpoint = "https://gitlab.vulk.coop/api/v4" # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
    config.private_token = ENV["GITLAB_TOKEN"] # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
  end

  @g = Gitlab.client(endpoint: ENV["GITLAB_API"], private_token: ENV["GITLAB_TOKEN"])
end 

def get_project_names
  Tuple.new([:ok, gitlab_client.projects.reduce([]) {|x,y| x << y.name}.to_json ])
end 

def get_projects 
  Tuple.new([:ok, gitlab_client.projects.reduce([]) {|x,y| x << y.to_hash}.to_json ])
end 

def get_pipelines(project_id)
  Tuple.new([:ok, gitlab_client.pipelines(project_id).reduce([]) {|x,y| x << y.status}.to_json ])
end 
