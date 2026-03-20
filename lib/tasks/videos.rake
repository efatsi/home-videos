namespace :videos do
  desc "Scan Spaces and sync video records to the database"
  task sync: :environment do
    SyncVideosService.call
  end
end
