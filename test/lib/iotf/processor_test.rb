require "test/test_helper"

class Iotf::ProcessorTest < MiniTest::Test

  def test_file_does_not_exist
    iotf = Iotf::Processor.new({})
    assert !iotf.exist?, "should not exist"
  end

  def test_file_exist
    iotf = Iotf::Processor.new({splat: "/test/image.jpg"})
    iotf.stub(:cached_file, "/local/file/test/image.jpg") do
      assert iotf.exist?, "should exist"
    end
  end

  def test_options_parsing
    params = {
      "splat" => "path/to/image.jpg",
      "h" => 100,
      "w" => "120"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal params["splat"], iotf.image_path
    assert_equal 100, iotf.options[:height]
    assert_equal 120, iotf.options[:width]

    assert_equal 1, iotf.procedures.length
    assert_equal :resize, iotf.procedures.first
  end

  def test_resize_with_x_args
    params = {
      "splat" => "path/to/image.jpg",
      "resize" => "100x120"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal 100, iotf.options[:width]
    assert_equal 120, iotf.options[:height]
    assert_equal 1, iotf.procedures.length
    assert_equal :resize, iotf.procedures.first   
  end

  def test_resize_with_comma_args
    params = {
      "splat" => "path/to/image.jpg",
      "resize" => "100,120,fill"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal 100, iotf.options[:width]
    assert_equal 120, iotf.options[:height]
    assert_equal "fill", iotf.options[:fit]

    assert_equal 1, iotf.procedures.length
    assert_equal :resize, iotf.procedures.first   
  end

  def test_crop_with_commas_args
    params = {
      "splat" => "path/to/image.jpg",
      "crop" => "10,11,120,100"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal 10, iotf.options[:left]
    assert_equal 11, iotf.options[:top]
    assert_equal 120, iotf.options[:width]
    assert_equal 100, iotf.options[:height]

    assert_equal 1, iotf.procedures.length
    assert_equal :crop, iotf.procedures.first   
  end

  def test_crop_with_x_and_commas_args
    params = {
      "splat" => "path/to/image.jpg",
      "crop" => "10,11,120x100"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal 10, iotf.options[:left]
    assert_equal 11, iotf.options[:top]
    assert_equal 120, iotf.options[:width]
    assert_equal 100, iotf.options[:height]

    assert_equal 1, iotf.procedures.length
    assert_equal :crop, iotf.procedures.first   
  end

  def test_rotate_args
    params = {
      "splat" => "path/to/image.jpg",
      "rotate" => "45"
    }
    iotf = Iotf::Processor.new(params)

    assert_equal 45, iotf.options[:rotation]
    assert_equal 1, iotf.procedures.length
    assert_equal :rotate, iotf.procedures.first
  end

  def test_background_args
    params = {
      "splat" => "path/to/image.jpg",
      "background" => "45,46,47"
    }
    iotf = Iotf::Processor.new(params)
    assert_equal [45, 46, 47], iotf.options[:background]
  end

end