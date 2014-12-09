require 'optparse'

PRELUDE = ["G21", "M107", "M104 S180", "G28 X0 Y0", "G29", "M109 S180", "G90", "G92 E0"]
FOOTER = ["G92 E0", "M107", "M104 S0", "G28 X0", "G28 Y0", "M84"]
LAYER_HEIGHT = 0.4
MAX_WIDTH = 100.0
CENTER_X = MAX_WIDTH / 2.0
CENTER_Y = MAX_WIDTH / 2.0
FEED_RATE = 800.00
START_Z = 0.350
NORMAL_TEMP = 180.0
HIGH_TEMP = 220.0

$extrude = 0.0
$current_temp = NORMAL_TEMP

def build_prelude
  puts
  PRELUDE.each {|code| puts code }
end

def build_footer
  puts
  FOOTER.each {|code| puts code }
end

def build_square(start_x, start_y, length)
  puts "G0 X#{start_x} Y#{start_y}"
  $extrude += length/5
  puts "G1 F#{FEED_RATE}"
  puts "G1 X#{start_x + length} Y#{start_y} E#{$extrude}"
  $extrude += length/5
  puts "G1 F#{FEED_RATE}"
  puts "G1 X#{start_x + length} Y#{start_y + length} E#{$extrude}"
  $extrude += length/5
  puts "G1 F#{FEED_RATE}"
  puts "G1 X#{start_x} Y#{start_y + length} E#{$extrude}"
  $extrude += length/5
  puts "G1 F#{FEED_RATE}"
  puts "G1 X#{start_x} Y#{start_y} E#{$extrude}"
end

def build_square_infill(start_x, start_y, length)
  (0.0..(length/2.0 - 1.5)).step(1).each do |offset|
    build_square(start_x + offset, start_y + offset, length - 2*(offset).abs)
  end
end

def switch_temp(temp)
  reset_extruder
  puts "G1 X0 Y0"
  puts "M104 S#{temp}"
  puts "M109 S#{temp}"
  puts "E20.0"
  reset_extruder
  $current_temp = temp
end

def reset_extruder
  puts "G92 E0"
  $extrude = 0.0
end

def set_z_value(layer_height, feed_rate = FEED_RATE)
  puts "G1 Z#{layer_height} F#{feed_rate}"
end

def build_pyramid(base_width, start_x, start_y, use_color, stripe_height)
  build_prelude
  reset_extruder
  skirt_width = [base_width + 20.0, MAX_WIDTH - 10].min
  build_square(CENTER_X - skirt_width/2.0, CENTER_Y - skirt_width/2.0, skirt_width)
  reset_extruder

  height = base_width * Math.sqrt(2)/2.0
  number_of_layers = (height - START_Z)/LAYER_HEIGHT
  end_z = (number_of_layers+1)*LAYER_HEIGHT + START_Z

  layers = (START_Z..end_z).step(LAYER_HEIGHT)
  colored_layer_heights = []
  if use_color
    stripe_layers = stripe_height / LAYER_HEIGHT
    colored_layers = (0..number_of_layers-1).partition {|layer| layer % (2.0*stripe_layers) < stripe_layers }[0]
    colored_layer_heights = colored_layers.map {|layer| LAYER_HEIGHT * layer + START_Z}
  end

  (START_Z..end_z).step(LAYER_HEIGHT).each do |layer_height|
    reset_extruder
    set_z_value(layer_height)

    start_x_offset = start_x + (layer_height - START_Z)/(Math.sqrt(2))
    start_y_offset = start_y + layer_height/(Math.sqrt(2))
    width = base_width - layer_height / (Math.sqrt(2)/2.0)

    if use_color && colored_layer_heights.include?(layer_height)
      switch_temp(HIGH_TEMP) if $current_temp != HIGH_TEMP
    elsif use_color && !colored_layers.include?(layer_height)
      switch_temp(NORMAL_TEMP) if $current_temp != NORMAL_TEMP
    end

    build_square(start_x_offset, start_y_offset, width)
    build_square_infill(start_x_offset, start_y_offset, width)
  end

  build_footer
end

def build_circle(start_x, start_y, radius)
  puts "G1 X#{start_x} Y#{start_y}"
  new_x = start_x - radius
  circumference = (2*Math::PI*radius).round(4)
  puts "G1 X#{new_x.round(4)} Y#{start_y.round(4)}"
  puts "G1 F#{FEED_RATE}"
  $extrude += circumference.round(4)/10.0
  puts "G2 I#{radius} E#{$extrude.round(4)}"
end

def build_circular_layer(start_x, start_y, radius_max)
  (0.4..radius_max).step(0.4).to_a[0..-2].each do |radius|
    build_circle(start_x, start_y, radius)
  end
end

def build_curved_object(start_x, start_y, radius, height, calc_radius, use_color, stripe_height)
  end_z = START_Z + height
  number_of_layers = (height - START_Z)/LAYER_HEIGHT
  (START_Z..end_z).step(LAYER_HEIGHT).each_with_index do |z_value, i|
    reset_extruder
    set_z_value(z_value.round(4), 800.00)
    radius_max = calc_radius.call(radius, z_value)

    layers = (START_Z..end_z).step(LAYER_HEIGHT)
    colored_layer_heights = []
    if use_color
      stripe_layers = stripe_height / LAYER_HEIGHT
      colored_layers = (0..number_of_layers-1).partition {|layer| layer % (2.0*stripe_layers) < stripe_layers }[0]
      colored_layer_heights = colored_layers.map {|layer| LAYER_HEIGHT * layer + START_Z}
    end

    if use_color && colored_layer_heights.include?(z_value)
      switch_temp(HIGH_TEMP) if $current_temp != HIGH_TEMP
    elsif use_color && !colored_layers.include?(z_value)
      switch_temp(NORMAL_TEMP) if $current_temp != NORMAL_TEMP
    end

    build_circle(start_x, start_y, radius_max)
    build_circular_layer(start_x, start_y, radius_max) if i % 2 == 0
  end
  build_footer
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_shape.rb [options]"
  opts.on("-s", "--shape SHAPE") do |shape|
    options[:shape] = shape
  end

  opts.on("-r", "--radius RADIUS") do |radius|
    options[:radius] = radius.to_f
  end

  opts.on("-w", "--width WIDTH") do |width|
    options[:width] = width.to_f
  end

  opts.on("--height HEIGHT") do |height|
    options[:height] = height.to_f
  end

  opts.on("--stripe") do
    options[:stripe] = true
  end

  opts.on("--stripe_height HEIGHT") do |height|
    options[:stripe_height] = height.to_f
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

shape = options[:shape].to_s.downcase

if options[:stripe] && options[:stripe_height] == nil
  puts "Please supply the stripe height"
  exit
elsif shape == 'pyramid'
  if (radius = options[:width]) == nil
    puts "Please supply the width of the base"
    exit
  end
  base_length = options[:width].to_f
  build_pyramid(base_length, CENTER_X - base_length/2.0, CENTER_Y - base_length/2.0, options[:stripe], options[:stripe_height])
elsif shape == 'cone' || shape == 'cylinder'
  if (radius = options[:radius]) == nil
    puts "Please supply the radius of the base"
    exit
  elsif (height = options[:height]) == nil
    puts "Please supply the height of the cone"
    exit
  end
  if shape == 'cone'
    calc_radius = Proc.new {|radius, z_value| (z_value - height)*-radius/height.to_f + START_Z }
  else
    calc_radius = Proc.new {|radius, z_value| radius }
  end
  build_prelude
  build_circle(CENTER_X, CENTER_Y, radius + 10.0)
  build_curved_object(CENTER_X, CENTER_Y, radius, height, calc_radius, options[:stripe], options[:stripe_height])
elsif shape == 'hemisphere'
  if (radius = options[:radius]) == nil
    puts "Please supply the radius of the base"
    exit
  end
  calc_radius = Proc.new {|radius, z_value| Math.sqrt(radius**2 - (z_value-START_Z)**2) }
  build_prelude
  build_circle(CENTER_X, CENTER_Y, radius + 10.0)
  build_curved_object(CENTER_X, CENTER_Y, radius, radius, calc_radius, options[:stripe], options[:stripe_height])
else
  puts "Please supply a shape (pyramid, cone, hemisphere)"
  exit
end
