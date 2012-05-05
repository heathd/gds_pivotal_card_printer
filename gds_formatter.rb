require 'rubygems'
require 'prawn'
require "prawn/measurement_extensions"
require 'rainbow'
require 'ostruct'

class GdsFormatter < PivotalToPdf::Formatters::Base
  def write_to(destination)
    @pdf = Prawn::Document.new(:page_layout => :portrait,
                             :margin      => 10.mm,
                             :page_size   => 'A4')

    stories.each_slice(2).with_index do |story_pair, i|
      @pdf.start_new_page unless i == 0
      render_page(story_pair)
    end

    @pdf.render_file "#{destination}.pdf"

    puts ">>> Generated PDF file in '#{destination}.pdf'".foreground(:green)
  rescue Exception
    puts "[!] There was an error while generating the PDF file... What happened was:".foreground(:red)
    raise
  end

  def render_page(story_pair)
    offset = @pdf.bounds.top - card_border_width / 2
    story_pair.each_with_index do |story, index| 
      render_story(story, offset - index * (card_height + card_border_width + vertical_space_between_cards))
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
    @pdf.stroke_color = story.story_color
    @pdf.line_width = card_border_width

    @pdf.stroke_rectangle [card_left_edge, offset], card_width, card_height
    padding = OpenStruct.new(x: card_border_width / 2 + 5.mm, y: card_border_width / 2 + 5.mm)

    @pdf.bounding_box(
      [card_left_edge + padding.x, offset - padding.y],
      width: card_width - padding.x * 2, 
      height: card_height - padding.y * 2) do

      # Crest
      @pdf.image File.join(File.dirname(__FILE__), "coat-of-arms.jpg"), at: [0, @pdf.bounds.right - 60.mm], fit: [60.mm, 60.mm]

      # Title
      @pdf.fill_color "000000"
      @pdf.text story.formatted_name, :size => 15.mm, :inline_format => true
      
      # Tags
      @pdf.image File.join(File.dirname(__FILE__), "label_icon.jpg"), at: [0, @pdf.cursor], fit: [6.mm, 6.mm]
      @pdf.fill_color "52D017"
      @pdf.text_box story.label_text, :size => 8.mm, at: [12.mm, @pdf.cursor]
      @pdf.move_down 15.mm
      
      # Description
      @pdf.fill_color "444444"
      text = if story.story_type == 'feature'
        first_paragraph_of(story.formatted_description)
      else
        story.formatted_description || ""
      end
      @pdf.text_box text, 
        size: 10.mm,
        inline_format: true,
        at: [0, @pdf.cursor],
        height: @pdf.cursor - 16.mm,
        overflow: :shrink_to_fit

      # Meta
      @pdf.fill_color "000000"
      @pdf.text_box story.points, 
        :size => 12.mm, 
        :at => [0, padding.y + 12.mm], 
        :width => card_width - 15.mm,
        valign: :bottom unless story.points.nil?

      @pdf.fill_color "999999"
      @pdf.text_box story.story_type.capitalize, 
        :size => 12.mm,
        :align => :right, 
        :at => [@pdf.bounds.right - 80.mm, padding.y + 12.mm], 
        :width => 80.mm,
        valign: :bottom

    end
  end

  def first_paragraph_of(text)
    paras = (text || "").split(/(?:(?:\n|\r\n)[\r\t ]*){2,}/)
    paras[0] || ""
  end
end
