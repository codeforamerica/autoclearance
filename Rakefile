# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'
require 'bundler/audit/task'

Rails.application.load_tasks

Bundler::Audit::Task.new

task default: 'bundle:audit'
