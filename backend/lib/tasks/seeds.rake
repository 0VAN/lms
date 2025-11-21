namespace :db do
  desc 'Seed the in-memory store with sample data (configurable via SEED_PRESET)'
  task seed: :environment do
    load Rails.root.join('db', 'seeds.rb')
  end
end

namespace :seed do
  desc 'Alias for db:seed to make sample data loading obvious'
  task load: 'db:seed'
end
