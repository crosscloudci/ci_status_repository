require Logger;
require IEx;
defmodule CncfDashboardApi.DataMigrations do
  # use EctoConditionals, repo: CncfDashboardApi.Repo

  defmacro upsert_from_map(repo, map, key_model, model, column_map) do
    quote do
      # projects = GitLabProxy.get_gitlab_projects 
      projects = unquote(map)

      # 1) log that we are starting the load
      Logger.info fn ->
        "Upsert Projects"
      end

      # 2) get the list of all source records and loop through them
      #
      #   LegacyEducationalInstitution.all.each do |legacy_educational_institution|

      upserted_count = Enum.reduce(projects, 0, fn(source_project, acc) -> 

        # 3) find out if the unique key from the source is already saved locally in the local uniquekey table
        # 4.a) initialize a new local uniquekey record with the key from the source
        # or 
        # 4.b) retrieve local uniquekey record with the unique key from the source 

        #     lkp = LegacyKeysEducationalInstitution.find_or_initialize_by(legacy_id: legacy_educational_institution.EducationalInstitutionId)

        # {skp_found, skp_record} = %CncfDashboardApi.SourceKeyProjects{source_id: Integer.to_string(source_project["id"])} |> find_by(:source_id)
        {skp_found, skp_record} = %unquote(key_model){source_id: Integer.to_string(source_project["id"])} |> find_by(:source_id)

        # 5.a) create a new local record 
        # or 
        # 5.b) retrieve local record with the local key from the source's uniquekey table 
        #     educational_institution = EducationalInstitution.find_or_initialize_by(id: lkp.new_id)
        #

        # {sp_found, sp_record} = %CncfDashboardApi.Projects{id: (skp_record.new_id || -1)} |> find_by(:id)
        {sp_found, sp_record} = %unquote(model){id: (skp_record.new_id || -1)} |> find_by(:id)
        case sp_found do
          :not_found ->
          Logger.info fn ->
            "upsert: sp_found not found"
          end
          # sp_record = %CncfDashboardApi.Projects{}
          sp_record = %unquote(model){}
          _ -> :ok
        end

        # 6) populate the local record with the rest of the information from the source (don't save yet)
        #     # fill in record from legacy record
        #     educational_institution.company_name = legacy_educational_institution.companyName
        #     educational_institution.short_name = legacy_educational_institution.shortName

        # changeset = CncfDashboardApi.Projects.changeset(sp_record, %{name: source_project["name"]})
        #
        # %{<<:source_column_name1>>, <<:destination_column_name1>>,<<:source_column_name2>>, <<:destination_column_name2>> 
        # e.g. %{name: "name", description: "desc1"}  
        # changeset = unquote(model).changeset(sp_record, %{name: source_project["name"]})
        #
        # Need to make a map:
        # 1. This: %{name: "name", description: "desc1"}  
        # 2. Expands into this: %{name: source_project["name"], description: source_project["desc1"]}   
        # 3. Which expands into this: %{name: "kubernetes", description: "Container project"}
        # build the destination changeset
        cs1 = Enum.reduce(unquote(column_map), %{}, 
                                  fn (x,acc) -> 
                                    Map.put(acc, elem(x,1), source_project[elem(x,0) 
                                    |> Atom.to_string]) 
                                  end
        ) 
        Logger.info fn ->
          "changeset: #{inspect(cs1)}"
        end
        changeset = unquote(model).changeset(sp_record, cs1)

        # 7) save the local record
        #     educational_institution.save!

        case sp_found do
          :found ->
            # {_, sp_record} = CncfDashboardApi.Repo.update(changeset) 
            {_, sp_record} = unquote(repo).update(changeset) 
          :not_found ->
            # {_, sp_record} = CncfDashboardApi.Repo.insert(changeset) 
            {_, sp_record} = unquote(repo).insert(changeset) 
        end

        # 8) save the uniquekey record

        #     lkp.new_id = educational_institution.id
        #     lkp.save!

        # changeset = CncfDashboardApi.SourceKeyProjects.changeset(skp_record, %{new_id: sp_record.id})
        changeset = unquote(key_model).changeset(skp_record, %{new_id: sp_record.id})
        case skp_found do
          :found ->
            # {_, skp_record} = CncfDashboardApi.Repo.update(changeset) 
            {_, skp_record} = unquote(repo).update(changeset) 
          :not_found ->
            # {_, skp_record} = CncfDashboardApi.Repo.insert(changeset) 
            {_, skp_record} = unquote(repo).insert(changeset) 
        end
  		  acc + 1
      end) 
    upserted_count
    end
  end
end
