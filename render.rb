#!/usr/bin/env ruby

require 'yaml'
require 'pivotal_tracker'
require 'pp'

require_relative "lib/configuration"
require_relative "lib/gds_pivotal_card_renderer"

# to debug connection issues
# RestClient.log = $stderr
configuration = Configuration.load
PivotalTracker::Client.token = configuration.token
PivotalTracker::Client.use_ssl = true

puts "Connecting to Pivotal Tracker..."
project = PivotalTracker::Project.find(configuration.project_id)
iteration = project.iteration(:current)

puts "Iteration \##{iteration.number}"
puts "  #{iteration.start.strftime("%a %d/%m/%y")} - " +
  "#{(iteration.finish - 1).strftime("%a %d/%m/%y")}"

stories = iteration.stories
puts "  #{stories.size} stories."

puts ""
renderer = GdsPivotalCardRenderer.new(stories)
output_filename = "iteration-#{iteration.number}.pdf"
renderer.render_to(output_filename)
puts "Wrote #{stories.size} stories to #{output_filename}"