module GdsPivotalCardPrinter
  class RenderJob
    def initialize(options = {})
      @configuration = Configuration.load
      PivotalTracker::Client.token = @configuration.token
      PivotalTracker::Client.use_ssl = true
      @renderer_class = options[:renderer_class] || A6Renderer
    end

    def project
      @project ||= begin
        puts "Connecting to Pivotal Tracker..."
        PivotalTracker::Project.find(@configuration.project_id)
      end
    end

    def stories
      raise "not implemented"
    end

    def output_filename
      raise "not implemented"
    end

    def render
      puts "  #{stories.size} stories."

      puts ""
      renderer = @renderer_class.new(stories)
      renderer.render_to(output_filename)
      puts "Wrote #{stories.size} stories to #{output_filename}"
    end
  end

  class RenderLabelJob < RenderJob
    def initialize(options = {})
      super
      @label = options[:label]
    end

    def stories
      stories = project.stories.all(label: @label)
    end

    def output_filename
      "label-#{@label}.pdf"
    end
  end

  class RenderIterationJob < RenderJob
    def initialize(options = {})
      super
      @iteration_selector = options[:iteration_selector]
    end

    def iteration
      @iteration ||= if @iteration_selector == :current
        project.iteration(:current)
      else
        project.iterations.all(offset: @iteration_selector-1, limit: 1).first
      end
    end

    def stories
      @stories ||= begin
        puts "Iteration \##{iteration.number}"
        puts "  #{iteration.start.strftime("%a %d/%m/%y")} - " +
          "#{(iteration.finish - 1).strftime("%a %d/%m/%y")}"

        iteration.stories
      end
    end

    def output_filename
      "iteration-#{iteration.number}.pdf"
    end
  end
end