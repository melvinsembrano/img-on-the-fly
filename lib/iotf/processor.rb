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

      @final_path = File.join(File.dirname(cached_file), "#{ SecureRandom.hex(2) }-#{ File.basename(cached_file) }")

      @pipeline = ImageProcessing::Vips
      @pipeline = @pipeline.source(cached_file)
      procedures.each { |p|  self.send(p.to_sym) if self.respond_to?(p.to_sym) }
      @pipeline.call(destination: @final_path)

      @final_path
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
      @image_path = [opts[:splat]].flatten.first
      @options[:width] = (opts[:w] || opts[:wid] || opts[:width]).to_f
      @options[:height] = (opts[:h] || opts[:hei] || opts[:height]).to_f
      @options[:fit] = opts[:fit] || "fill"

      # add more extraction here
      if @procedures.empty? && @options[:width] > 0 && @options[:height] > 0
        @procedures << "resize" 
      end
    end

    def resize
      resize_command = case @options[:fit]
      when "fill", "crop"
        @pipeline = @pipeline.resize_to_fill @options[:width], @options[:height]
      else
        @pipeline = @pipeline.resize_to_fit @options[:width], @options[:height]
      end
    end

  end
end
