require 'prawn'
require "prawn/measurement_extensions"
require 'ostruct'

module GdsPivotalCardPrinter
  class SixByFourRenderer
    TITLE_SIZE = 12.mm
    DESCRIPTION_SIZE = 7.mm

    def self.description
      "6x4 record cards (use manual feed)"
    end

    def initialize(stories, opts = {})
      @stories = stories
      @scale = 1
      @opts = opts
      @iteration = opts[:iteration]
      @iteration_number = @iteration.id if @iteration
    end

    def render_to(destination)
      @pdf = Prawn::Document.new(:page_layout => :landscape,
                               :margin      => 0,
                               :page_size   => [102.mm, 152.mm])


      @stories.each.with_index do |story, i|
        @pdf.start_new_page unless i == 0
        render_story(story)
      end

      @pdf.render_file destination
    rescue Exception
      puts "[!] There was an error while generating the PDF file... What happened was:"
      raise
    end

    private

    def card_border_width
      2.mm
    end

    def paper_margin
      5.mm
    end

    def card_height
      @pdf.bounds.height - paper_margin * 2 - card_border_width
    end

    def card_width
      @pdf.bounds.width - paper_margin * 2 - card_border_width
    end

    def card_left_edge
      @pdf.bounds.left + paper_margin + card_border_width / 2
    end

    def offsets_for_position(page_position)
      x = page_position % 2
      y = page_position / 2

      x_offset = @pdf.bounds.left + paper_margin + card_border_width / 2
      y_offset = @pdf.bounds.top - paper_margin - card_border_width / 2
      x_offset += x * (card_width + paper_margin * 2 + card_border_width)
      y_offset -= y * (card_height + paper_margin * 2 + card_border_width)
      [x_offset, y_offset]
    end

    # page_position from 0-3
    def render_story(story)
      x_offset, y_offset = offsets_for_position(0)
      @pdf.stroke_color = story_color(story)
      @pdf.line_width = card_border_width

      @pdf.stroke_rectangle [x_offset, y_offset], card_width, card_height
      padding_x = card_border_width / 2 + 6.mm
      padding_y = card_border_width / 2 + 6.mm

      @pdf.bounding_box(
        [x_offset + padding_x, y_offset - padding_y],
        width: card_width - padding_x * 2,
        height: card_height - padding_y * 2) do

        render_crest
        render_story_title(story)
        render_story_points(story, padding_y)
      end
      render_iteration_number(story)
    end

    def image_path(filename)
      File.join(File.dirname(__FILE__), "..", "..", "images", filename)
    end

    def render_crest
      crest_size = 20.mm * @scale
      @pdf.image image_path('coat-of-arms.png'),
        at: [(@pdf.bounds.right - crest_size)/2, crest_size - 5.mm],
        fit: [crest_size, crest_size]
    end

    def render_story_title(story)
      @pdf.fill_color "000000"
      @pdf.text story.name, :size => TITLE_SIZE * @scale, :inline_format => true, :align => :center

    end

    def render_story_tags(story)
      label_text = (story.labels || "").strip
      if ! label_text.empty?
        @pdf.image image_path("label_icon.jpg"), at: [0, @pdf.cursor], fit: [6.mm * @scale, 6.mm * @scale]
        @pdf.fill_color "52D017"
        @pdf.text_box label_text, :size => 7.mm * @scale, at: [12.mm * @scale, @pdf.cursor]
        @pdf.move_down 10.mm * @scale
      end
    end

    def render_story_description(story)
      text = story.description || ""
      text = first_paragraph_of(text) if story.story_type == 'feature'
      @pdf.fill_color "666666"
      @pdf.move_down DESCRIPTION_SIZE
      @pdf.font "Times-Roman" do
        leading = count_lines(text) > 2 ? 1 : 6
        @pdf.text_box text,
          size: DESCRIPTION_SIZE * @scale,
          inline_format: true,
          at: [0, @pdf.cursor],
          height: @pdf.cursor - 18.mm * @scale,
          leading: leading * @scale,
          overflow: :shrink_to_fit
      end
    end

    def render_story_points(story, padding_y)
      if story.story_type == 'feature'
        @pdf.fill_color "000000"
        @pdf.font "Helvetica", :style => :bold do
          @pdf.text_box story_points(story),
            :size => 12.mm * @scale,
            :at => [0, padding_y + 12.mm * @scale],
            :width => card_width - 15.mm * @scale,
            valign: :bottom
          end
      end
    end

    def render_iteration_number(story)
      @pdf.fill_color "000000"
      text_height = 6.mm * @scale
      @pdf.text_box @iteration_number.to_s,
        :size => text_height,
        :at => [@pdf.bounds.right - paper_margin - card_border_width - 10.mm,
          @pdf.bounds.bottom + paper_margin + card_border_width + text_height + 1.mm],
        :width => 15.mm,
        valign: :top,
        alighn: :right
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
        ""
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