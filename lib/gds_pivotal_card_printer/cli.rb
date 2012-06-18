require 'thor'

module GdsPivotalCardPrinter
  class Cli < ::Thor
    desc "current", "print stories for the current iteration into a PDF file"
    def current
      render :current
    end

    desc "iteration ITERATION-NUMBER", "print all the stories for the iteration specified into a PDF file"
    def iteration(iteration_number)
      render iteration_number.to_i
    end

    desc "label LABEL", "print all stories with a given label"
    def label(label)
      render_label(label)
    end
  
    private

    def setup_project_to_render
      configuration = Configuration.load
      PivotalTracker::Client.token = configuration.token
      PivotalTracker::Client.use_ssl = true

      puts "Connecting to Pivotal Tracker..."
      project = PivotalTracker::Project.find(configuration.project_id)
      return project
    end

    def render_label(label)
      project = setup_project_to_render
      stories = project.stories.all(label: label)

      puts "  #{stories.size} stories."
      puts ""

      renderer = Renderer.new(stories)
      output_filename = "label-#{label}.pdf"
      renderer.render_to(output_filename)
      puts "Wrote #{stories.size} stories to #{output_filename}"
    end

    def render(iteration_selector)
      project = setup_project_to_render

      iteration = if iteration_selector == :current
        project.iteration(:current)
      else
        project.iterations.all(offset: iteration_selector-1, limit: 1).first
      end

      puts "Iteration \##{iteration.number}"
      puts "  #{iteration.start.strftime("%a %d/%m/%y")} - " +
        "#{(iteration.finish - 1).strftime("%a %d/%m/%y")}"

      stories = iteration.stories

      puts "  #{stories.size} stories."

      puts ""
      renderer = Renderer.new(stories)
      output_filename = "iteration-#{iteration.number}.pdf"
      renderer.render_to(output_filename)
      puts "Wrote #{stories.size} stories to #{output_filename}"
    end
  end
end