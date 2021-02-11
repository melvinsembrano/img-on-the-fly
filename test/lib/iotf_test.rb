require "test/test_helper"

class IotfTest < MiniTest::Test

  def test_file_does_not_exist
    iotf = Iotf.new({})
    assert !iotf.exist?, "should not exist"
  end

  def test_file_exist
    iotf = Iotf.new({splat: "/test/image.jpg"})
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
    iotf = Iotf.new(params)

    assert_equal params["splat"], iotf.image_path
    assert_equal 100, iotf.options[:height]
    assert_equal 120, iotf.options[:width]
    assert_equal "fill", iotf.options[:fit]

    assert_equal 1, iotf.procedures.length
    assert_equal "resize", iotf.procedures.first
  end

end