# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'bundler/audit/task'
  Bundler::Audit::Task.new

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  task default: %w[bundle:audit rubocop]
rescue NameError, LoadError
  # bundler-audit is not available
end
