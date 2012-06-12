#!/usr/bin/env bundle exec ruby

require 'yaml'
require 'pivotal_tracker'

require_relative "lib/gds_pivotal_card_printer/cli"
require_relative "lib/gds_pivotal_card_printer/configuration"
require_relative "lib/gds_pivotal_card_printer/renderer"

# to debug connection issues
RestClient.log = $stderr if ENV['DEBUG']

GdsPivotalCardPrinter::Cli.start

