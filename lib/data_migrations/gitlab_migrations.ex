require Logger;
require IEx;
require CncfDashboardApi.DataMigrations;
defmodule CncfDashboardApi.GitlabMigrations do
  use EctoConditionals, repo: CncfDashboardApi.Repo

	def save_project_names do
		projects = GitLabProxy.get_gitlab_project_names
		Enum.map(projects, fn(source_project) -> 

			prec = %CncfDashboardApi.Projects{name: source_project} 
			CncfDashboardApi.Repo.insert(prec) 
		end) 
  end

	def upsert_projects do
    CncfDashboardApi.DataMigrations.upsert_from_map(
      CncfDashboardApi.Repo,
      GitLabProxy.get_gitlab_projects,
      CncfDashboardApi.SourceKeyProjects,
      CncfDashboardApi.Projects,
      %{name: :name}
    )
  end
end
