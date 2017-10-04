defmodule CncfDashboardApi.Scheduler do
  use Quantum.Scheduler, otp_app: :your_app

	def save_projects do
		projects = RubyElixir.GitLabProxy.get_gitlab_projects 
		# p1 = %CncfDashboardApi.Projects{name: "myproject"} 
		# CncfDashboardApi.Repo.insert(p1) 
		Enum.map(projects, fn(x) -> 
			prec = %CncfDashboardApi.Projects{name: x} 
			CncfDashboardApi.Repo.insert(prec) 
			inspect(x) 
		end) 


		# 1) log that we are starting the load

		# 2) get the list of all source records and loop through them

		#   LegacyProvider.all.each do |legacy_provider|

		# 3) find out if the unique key from the source is already saved locally in the local uniquekey table

		# 4.a) create a new local uniquekey record with the key from the source
		# or 
		# 4.b) retrieve local uniquekey record with the unique key from the source 

		#     lkp = LegacyKeysProvider.find_or_initialize_by(legacy_id: legacy_provider.ProviderId)

		# 5.a) create a new local record 
		# or 
		# 5.b) retrieve local record with the local key from the source's uniquekey table 
		#     provider = Provider.find_or_initialize_by(id: lkp.new_id)

		# 6) populate the local record with the rest of the information from the source (don't save yet)

		#     # fill in record from legacy record
		#     provider.company_name = legacy_provider.companyName
		#     provider.short_name = legacy_provider.shortName

		# 7) save the local record

		#     provider.save!

		# 8) save the uniquekey record

		#     lkp.new_id = provider.id
		#     lkp.save!
	end
end
