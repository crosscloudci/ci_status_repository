require "gitlab"
require 'json'
require 'awesome_print'

def gitlab_client 
  Gitlab.configure do |config|
    config.endpoint = ENV["GITLAB_API"] 
    config.private_token = ENV["GITLAB_TOKEN"] 
  end

  @g = Gitlab.client(endpoint: ENV["GITLAB_API"], private_token: ENV["GITLAB_TOKEN"])
end 

def get_project_names
  Tuple.new([:ok, gitlab_client.projects.auto_paginate.reduce([]) {|x,y| x << y.name}.to_json ])
end 

def get_projects 
  Tuple.new([:ok, gitlab_client.projects.auto_paginate.reduce([]) {|x,y| x << y.to_hash}.to_json ])
end 

def get_project(project_id) 
  Tuple.new([:ok, gitlab_client.project(project_id).to_hash.to_json ])
end 

def get_pipelines(project_id)
  Tuple.new([:ok, gitlab_client.pipelines(project_id).auto_paginate.reduce([]) {|x,y| x << y.to_hash}.to_json ])
end 

def get_pipeline_jobs(project_id, pipeline_id)
  Tuple.new([:ok, gitlab_client.pipeline_jobs(project_id, pipeline_id).auto_paginate.reduce([]) {|x,y| x << y.to_hash}.to_json ])
end 
