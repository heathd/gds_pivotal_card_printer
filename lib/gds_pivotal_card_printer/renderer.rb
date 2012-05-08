require 'prawn'
require "prawn/measurement_extensions"
require 'ostruct'

module GdsPivotalCardPrinter
  class::Renderer
    def initialize(stories)
      @stories = stories
    end
  
    def render_to(destination)
      @pdf = Prawn::Document.new(:page_layout => :portrait,
                               :margin      => 10.mm,
                               :page_size   => 'A4')

      @stories.each_slice(2).with_index do |story_pair, i|
        @pdf.start_new_page unless i == 0
        render_page(story_pair)
      end

      @pdf.render_file destination
    rescue Exception
      puts "[!] There was an error while generating the PDF file... What happened was:"
      raise
    end

    private
  
    def render_page(story_pair)
      offset = @pdf.bounds.top - card_border_width / 2
      step_size = card_height + card_border_width + vertical_space_between_cards
      story_pair.each_with_index do |story, index| 
        render_story(story, offset - index * step_size)
      end
    end

    def card_border_width
      3.mm
    end

    def vertical_space_between_cards
      1.mm
    end

    def card_height
      (@pdf.bounds.height - card_border_width * 2 - vertical_space_between_cards) / 2
    end

    def card_width
      @pdf.bounds.width - card_border_width
    end

    def card_left_edge
      @pdf.bounds.left + card_border_width / 2
    end

    def render_story(story, offset)
      @pdf.stroke_color = story_color(story)
      @pdf.line_width = card_border_width

      @pdf.stroke_rectangle [card_left_edge, offset], card_width, card_height
      padding_x = card_border_width / 2 + 6.mm
      padding_y = card_border_width / 2 + 6.mm
    
      @pdf.bounding_box(
        [card_left_edge + padding_x, offset - padding_y],
        width: card_width - padding_x * 2, 
        height: card_height - padding_y * 2) do

        render_crest
        render_story_title(story)
        # render_story_tags(story)
        # render_story_description(story)
        render_story_points(story, padding_y)
        render_story_type(story, padding_y)

      end
    end

    def image_path(filename)
      File.join(File.dirname(__FILE__), "..", "..", "images", filename)
    end
    
    def render_crest
      crest_size = 20.mm
      @pdf.image image_path('coat-of-arms.png'),
        at: [(@pdf.bounds.right - crest_size)/2, crest_size - 5.mm], 
        fit: [crest_size, crest_size]
    end
  
    def render_story_title(story)
      @pdf.fill_color "000000"
      @pdf.text story.name, :size => 18.mm, :inline_format => true, :align => :center

    end
  
    def render_story_tags(story)
      label_text = (story.labels || "").strip
      if ! label_text.empty?
        @pdf.image image_path("label_icon.jpg"), at: [0, @pdf.cursor], fit: [6.mm, 6.mm]
        @pdf.fill_color "52D017"
        @pdf.text_box label_text, :size => 7.mm, at: [12.mm, @pdf.cursor]
        @pdf.move_down 10.mm
      end
    end
  
    def render_story_description(story)
      text = story.description || ""
      text = first_paragraph_of(text) if story.story_type == 'feature'
      @pdf.fill_color "666666"
      @pdf.move_down 9.mm
      @pdf.font "Times-Roman" do
        leading = count_lines(text) > 2 ? 1 : 6
        @pdf.text_box text, 
          size: 9.mm,
          inline_format: true,
          at: [0, @pdf.cursor],
          height: @pdf.cursor - 18.mm,
          leading: leading,
          overflow: :shrink_to_fit
      end
    end
  
    def render_story_points(story, padding_y)
      if story.story_type == 'feature'
        @pdf.fill_color "000000"
        @pdf.text_box "Points: #{story_points(story)}", 
          :size => 12.mm, 
          :at => [0, padding_y + 12.mm], 
          :width => card_width - 15.mm,
          valign: :bottom
      end
    end
  
    def render_story_type(story, padding_y)
      @pdf.fill_color "aaaaaa"
      @pdf.text_box story.story_type.capitalize, 
        :size => 12.mm,
        :align => :right, 
        :at => [@pdf.bounds.right - 80.mm, padding_y + 12.mm], 
        :width => 80.mm,
        valign: :bottom
    end
  
    def story_color(story)
      case story.story_type
      when "feature" then "85994b"
      when "bug" then "b10e1e"
      when "chore" then "b58840"
      else "000000"
      end
    end

    def story_points(story)
      if story.respond_to?(:estimate) && !story.estimate.eql?(-1)
        story.estimate.to_s
      else
        "Not yet estimated"
      end
    end
    
    def count_lines(text)
      text.split("\n").size
    end
    
    def paragraphs(text)
      (text || "").split(/(?:(?:\n|\r\n)[\r\t ]*){2,}/)
    end
    
    def first_paragraph_of(text)
      paragraphs(text)[0] || ""
    end
  end
end