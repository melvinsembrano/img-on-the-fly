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

        when "resize"
          @procedures << k
          resize_args = v.split(/[\,,x]/)
          @options[:width] = (resize_args[0] || @options[:width]).to_f
          @options[:height] = (resize_args[1] || @options[:height]).to_f
          @options[:fit] = resize_args[2] || @options[:fit]

        # supported procs
        when "rotate", "crop", "composite", "convert", "collage"
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
      resize_command = case @options[:fit]

      when "fill"
        pipeline = pipeline.resize_to_fill @options[:width], @options[:height]
      when "pad"
        pipeline = pipeline.resize_and_pad @options[:width], @options[:height]
      else
        pipeline = pipeline.resize_to_fit @options[:width], @options[:height]
      end
    end

  end
end
