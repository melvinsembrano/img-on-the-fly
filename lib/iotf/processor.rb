require "vips"
require "securerandom"

module Iotf
  class Processor
    attr_accessor :procedures, :options, :image_path, :cached_file, :final_path

    def initialize(options)
      @procedures = []
      @options = {}
      parse_options options.transform_keys { |k| k.to_s.downcase.to_sym }
    end

    def execute!
      if !exist?
        raise "File not found"
      end

      # if no procedures return the original file
      if procedures.empty?
        return cached_file
      end

      final_path = File.join(File.dirname(cached_file), "#{ SecureRandom.hex(2) }-#{ File.basename(cached_file) }")
      process_image(cached_file, final_path)
      final_path
    end

    def process_image(source, destination, procs = nil)
      pipeline = ImageProcessing::Vips
      pipeline = pipeline.source(source)

      (procs || procedures).each { |p|  pipeline = self.send(p, pipeline) if self.respond_to?(p.to_sym) }

      pipeline.call(destination: destination)
    end

    def exist?(check_source: true)
      return false if image_path.to_s.empty?
      if check_source
        get_file_from_source
      else
        true
      end
    end

    def get_file_from_source
      return true unless cached_file.nil?
      @cached_file = Iotf::S3.new.download(image_path)
      !@cached_file.nil?
    end

    def parse_options(opts)
      opts.each do |k,v|
        case k.to_s.downcase
        when "splat"
          @image_path = [opts[:splat]].flatten.first
        when "w", "wid", "width"
            @options[:width] = v.to_f
        when "h", "hei", "height"
            @options[:height] = v.to_f

        when "background", "bg"
          @options[:background] = v.split(/[\,,x]/).map { |i| i.to_f }

        when "text"
          @procedures << :write_text
          @options[:text], @options[:text_args] = v.split("|")
          
        when "resize"
          @procedures << k
          resize_args = v.split(/[\,,x]/)
          @options[:width] = (resize_args[0] || @options[:width]).to_f
          @options[:height] = (resize_args[1] || @options[:height]).to_f
          @options[:fit] = resize_args[2] || @options[:fit]

        when "crop"
          if v == "smart"
            @procedures << :smart_crop
          else
            @procedures << k
            resize_args = v.split(/[\,,x]/)
            @options[:left] = resize_args[0].to_f
            @options[:top] = resize_args[1].to_f
            @options[:width] = (resize_args[2] || @options[:width]).to_f
            @options[:height] = (resize_args[3] || @options[:height]).to_f
          end

        when "rotate"
          @procedures << k
          resize_args = v.split(/[\,,x]/)
          @options[:rotation] = resize_args[0].to_f

        when "collage"
          @procedures << k
          @options["#{k}_args".to_sym] = v.split("|").map {|i| i.split(/[\,,x]/).map {|f| f.to_f } }

        # supported procs
        when "composite", "convert"
          @procedures << k
          @options["#{k}_args".to_sym] = v
        else
          @options[k.to_sym] = v
        end
      end

      # add more extraction here
      if @procedures.empty? && @options[:width].to_f > 0 && @options[:height].to_f > 0
        @procedures << :resize
      end
    end

    def resize(pipeline)
      case options[:fit]
      when "fill"
        return pipeline.resize_to_fill options[:width], options[:height]
      when "pad"
        return pipeline.resize_and_pad options[:width], options[:height]
      else
        return pipeline.resize_to_fit options[:width], options[:height]
      end
    end

    def crop(pipeline, crop_args=nil)
      left, top, width, height = crop_args || [options[:left], options[:top], options[:width], options[:height]]
      pipeline.crop left, top, width, height
    end

    def rotate(pipeline)
      background = options[:background] || [0, 0, 0]
      pipeline.rotate options[:rotation], background: options[:background]
    end

    def collage(pipeline)
      images = []
      width = 0
      height = 0
      background = options[:background] || [255, 255, 255]
      options[:collage_args].each_with_index do |cargs, i|
        images[i] = crop(pipeline, cargs).call
        width += cargs[2]
        height = cargs[3] if cargs[3] > height
      end
      width = width + ((images.length + 1) * 40 )
      height = height + 80
      puts images.inspect

      collage_pipeline = crop(pipeline, [0, 0, width, height])
        .draw_rect(background, 0, 0, width, height, fill: true)

      x = 40
      images.each_with_index do |img, i|
        y = (height * 0.5)  - (options[:collage_args][i][3] * 0.5)
        collage_pipeline = collage_pipeline.composite img, mode: "over", x: x, y: y
        x += options[:collage_args][i][2] + 40
      end
      collage_pipeline
    end

    def write_text(pipeline)
      puts "Writing text #{options}"
      text_args = (options[:text_args] || "0,0").split(/[\,,x]/).map { |i| i.to_f }
      background = options[:background] || [0, 0, 0, 0]

      text = Vips::Image
        .text(options[:text], dpi: 300)

      pipeline.insert text, text_args[0], text_args[1] # , background: background
    end

  end
end
