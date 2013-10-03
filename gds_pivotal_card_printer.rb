#!/usr/bin/env bundle exec ruby

require 'yaml'
require 'pivotal_tracker'
require 'slop'

require_relative "lib/gds_pivotal_card_printer/configuration"
require_relative "lib/gds_pivotal_card_printer/renderer"
require_relative "lib/gds_pivotal_card_printer/a6_renderer"
require_relative "lib/gds_pivotal_card_printer/six_by_four_renderer"
require_relative "lib/gds_pivotal_card_printer/jobs"

# to debug connection issues
RestClient.log = $stderr if ENV['DEBUG']

class Cli
  attr_reader :opts
  class BadCliOptionError < StandardError; end

  def initialize
    @opts = Slop.parse(help: true) do
      banner 'Usage: gds_pivotal_card_printer.rb [options]'

      on '-r=', 'renderer', "Choose layout renderer {a5|a6}."
      on '-c', 'current', "Print all stories in current iteration"
      on '-i=', 'iteration', "Print all stories with specified iteration number"
      on '-l=', 'label', 'Print all stories with specified label'
      on 'renderers', "List all layout renderers"
    end
  end

  def layouts
    {
      "6x4" => GdsPivotalCardPrinter::SixByFourRenderer,
      "a6" => GdsPivotalCardPrinter::A6Renderer,
      "a5" => GdsPivotalCardPrinter::Renderer
    }
  end

  def renderer_class
    layouts[opts[:renderer] || "a6"] || raise(BadCliOptionError, "Unknown layout renderer #{opts[:renderer]}")
  end

  def run
    if opts[:layouts]
      layouts.each do |key, layout|
        puts "#{key}: #{layout.description}"
      end
    elsif opts[:current]
      job = GdsPivotalCardPrinter::RenderIterationJob.new(iteration_selector: :current, renderer_class: renderer_class)
      job.render
    elsif opts[:iteration]
      job = GdsPivotalCardPrinter::RenderIterationJob.new(iteration_selector: opts[:iteration].to_i, renderer_class: renderer_class)
      job.render
    elsif opts[:label]
      job = GdsPivotalCardPrinter::RenderLabelJob.new(label: opts[:label], renderer_class: renderer_class)
      job.render
    else
      puts opts
    end
  rescue Slop::MissingArgumentError, BadCliOptionError => e
    puts "Error: #{e}\n\n"
    puts opts
  end
end

Cli.new.run