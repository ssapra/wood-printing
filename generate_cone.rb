PRELUDE = ["G21", "M107", "M104 S200", "G28 X0 Y0", "G29", "M109 S200", "G90", "G92 E0"]
FOOTER = ["G92 E0", "M107", "M104 S0", "G28 X0", "G28 Y0", "M84"]
LAYER_HEIGHT = 0.4
FEED_RATE = 1400.00
START_Z = 0.350

$extrude = 0.0

def build_circle(start_x, start_y, radius)
  puts "G1 X#{start_x} Y#{start_y}"
  new_x = start_x - radius
  circumference = (2*Math::PI*radius).round(4)
  puts "G1 X#{new_x.round(4)} Y#{start_y.round(4)}"
  puts "G1 F#{FEED_RATE}"
  $extrude += circumference.round(4)/10.0
  puts "G2 I#{radius} E#{$extrude.round(4)}"
end

def build_prelude
  puts
  PRELUDE.each {|code| puts code }
end

def build_footer
  puts
  FOOTER.each {|code| puts code }
end

def reset_extruder
  puts "G92 E0"
  $extrude = 0.0
end

def build_sphere(start_x, start_y, radius, height)
  build_prelude

  (START_Z..START_Z+height).step(LAYER_HEIGHT).each_with_index do |z_value, i|
    reset_extruder
    puts "G1 Z#{z_value.round(4)} F7800.000"

    radius_max = (z_value - height)*-radius/height.to_f + START_Z

    if i % 2 == 0
      (0.4..radius_max).step(0.4).each do |radius|
        build_circle(start_x, start_y, radius)
      end
    else
      build_circle(start_x, start_y, radius_max)
    end
  end
  build_footer
end

start_x = 50.0
start_y = 50.0
radius = 20.0
height = 50.0
build_circle(start_x, start_y, radius+ 20.0)
build_sphere(50.0, 50.0, radius, height)
