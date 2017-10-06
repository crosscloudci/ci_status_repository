require Logger;
require IEx;
defmodule CncfDashboardApi.Scheduler do
  use Quantum.Scheduler, otp_app: :cncf_dashboard_api
  use EctoConditionals, repo: CncfDashboardApi.Repo

	def save_project_names do
		projects = RubyElixir.GitLabProxy.get_gitlab_project_names
		Enum.map(projects, fn(source_project) -> 

			prec = %CncfDashboardApi.Projects{name: source_project} 
			CncfDashboardApi.Repo.insert(prec) 
		end) 
  end

	def upsert_projects do
		projects = RubyElixir.GitLabProxy.get_gitlab_projects 

    # 1) log that we are starting the load
      Logger.info fn ->
        "Upsert Projects"
      end

    # 2) get the list of all source records and loop through them
    #
    #   LegacyProvider.all.each do |legacy_provider|
    
		Enum.map(projects, fn(source_project) -> 

    # 3) find out if the unique key from the source is already saved locally in the local uniquekey table
    # 4.a) initialize a new local uniquekey record with the key from the source
    # or 
    # 4.b) retrieve local uniquekey record with the unique key from the source 
 
    #     lkp = LegacyKeysProvider.find_or_initialize_by(legacy_id: legacy_provider.ProviderId)
    
    {skp_found, skp_record} = %CncfDashboardApi.SourceKeyProjects{source_id: Integer.to_string(source_project["id"])} |> find_by(:source_id)

    # 5.a) create a new local record 
    # or 
    # 5.b) retrieve local record with the local key from the source's uniquekey table 
    #     provider = Provider.find_or_initialize_by(id: lkp.new_id)
    #
    
    {sp_found, sp_record} = %CncfDashboardApi.Projects{id: (skp_record.new_id || -1)} |> find_by(:id)
    case sp_found do
      :not_found ->
        Logger.info fn ->
          "upsert: sp_found not found"
        end
        sp_record = %CncfDashboardApi.Projects{}
      _ -> :ok
    end

    # 6) populate the local record with the rest of the information from the source (don't save yet)
    #     # fill in record from legacy record
    #     provider.company_name = legacy_provider.companyName
    #     provider.short_name = legacy_provider.shortName
    
    changeset = CncfDashboardApi.Projects.changeset(sp_record, 
                                                    %{name: source_project["name"]})


    # 7) save the local record
    #     provider.save!
    
    case sp_found do
      :found ->
        {_, sp_record} = CncfDashboardApi.Repo.update(changeset) 
      :not_found ->
        {_, sp_record} = CncfDashboardApi.Repo.insert(changeset) 
    end

    # 8) save the uniquekey record

    #     lkp.new_id = provider.id
    #     lkp.save!
    
    changeset = CncfDashboardApi.SourceKeyProjects.changeset(skp_record, %{new_id: sp_record.id})
    case skp_found do
      :found ->
        {_, skp_record} = CncfDashboardApi.Repo.update(changeset) 
      :not_found ->
        {_, skp_record} = CncfDashboardApi.Repo.insert(changeset) 
    end
    end) 

  end
end
