PRELUDE = ["G21", "M107", "M104 S200", "G28 X0 Y0", "G29", "M109 S200", "G90", "G92 E0"]
FOOTER = ["G92 E0", "M107", "M104 S0", "G28 X0", "G28 Y0", "M84"]
LAYER_HEIGHT = 0.4
FEED_RATE = 800.00
START_Z = 0.350

# Print prelude code
def build_prelude
  puts
  PRELUDE.each {|code| puts code }
end

def build_footer
  puts
  FOOTER.each {|code| puts code }
end

def make_square(start_x, start_y, length, lh)
  (0.0..(length/2.0 - 0.5)).step(1).each do |offset|
    new_start_x = start_x + offset
    new_start_y = start_y + offset
    new_length = length - 2*offset
    puts "G0 X#{new_start_x} Y#{new_start_y}"
    $extrude += new_length/5
    set_z_value(lh)
    puts "G1 X#{new_start_x + new_length} Y#{new_start_y} E#{$extrude}"
    $extrude += new_length/5
    set_z_value(lh)
    puts "G1 X#{new_start_x + new_length} Y#{new_start_y + new_length} E#{$extrude}"
    $extrude += new_length/5
    set_z_value(lh)
    puts "G1 X#{new_start_x} Y#{new_start_y + new_length} E#{$extrude}"
    set_z_value(lh)
    $extrude += new_length/5
    puts "G1 X#{new_start_x} Y#{new_start_y} E#{$extrude}"
  end
end

def switch_temp(temp)
  puts "G92 E0.0"
  puts "G1 X0 Y0"
  puts "M104 S#{temp}"
  puts "M109 S#{temp}"
end

def reset_extruder
  puts "G92 E0"
  $extrude = 0.0
end

def set_z_value(layer_height, feed_rate = FEED_RATE)
  puts "G1 Z#{layer_height} F#{feed_rate}"
end

def build_pyramid(base_width, start_x, start_y)
  build_prelude
  reset_extruder

  number_of_layers = base_width/LAYER_HEIGHT
  end_z = number_of_layers*LAYER_HEIGHT + START_Z

  (START_Z..end_z).step(LAYER_HEIGHT).each do |layer_height|
    reset_extruder
    set_z_value(layer_height)

    start_x_offset = start_x + layer_height
    start_y_offset = start_y + layer_height
    width = base_width - 2.0*layer_height
    make_square(start_x_offset, start_y_offset, width, layer_height)
  end

  build_footer
end

build_pyramid(80.0, 10.0, 10.0)
