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

      # "this will be a new image data from #{self.inspect} #{ cached_file }"
      @final_path = cached_file
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
      @procedures << "resize" if @procedures.empty?
    end
  end
end
