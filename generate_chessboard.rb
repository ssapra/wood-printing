prelude = ["G21", "M107", "M104 S200", "G28 X0 Y0", "G29", "M109 S200", "G90", "G92 E0"]
footer = ["G92 E0", "M107", "M104 S0", "G28 X0", "G28 Y0", "M84"]

# Print prelude code
prelude.each {|code| puts code }

number_of_layers = 10
PR = 800.00
puts "G92 E0"

def make_square(start_x, start_y, length, lh)
  (0.0..(length/2.0 - 0.5)).step(1).each do |offset|
    new_start_x = start_x + offset
    new_start_y = start_y + offset
    new_length = length - 2*offset
    puts "G0 X#{new_start_x} Y#{new_start_y}"
    $extrude += new_length/5
    puts "G1 Z#{lh} F#{PR}"
    puts "G1 X#{new_start_x + new_length} Y#{new_start_y} E#{$extrude}"
    $extrude += new_length/5
    puts "G1 Z#{lh} F#{PR}"
    puts "G1 X#{new_start_x + new_length} Y#{new_start_y + new_length} E#{$extrude}"
    $extrude += new_length/5
    puts "G1 Z#{lh} F#{PR}"
    puts "G1 X#{new_start_x} Y#{new_start_y + new_length} E#{$extrude}"
    puts "G1 Z#{lh} F#{PR}"
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

def make_colored_squares(light, layer_height)
  (10.0..80.0).step(10.0).each_with_index do |start_x, i|
    (10.0..80.0).step(10.0).each_with_index do |start_y, j|
      make_square(start_x, start_y, 10.0, layer_height) if (i+j) % 2 == light
    end
  end
end

(0.350..((number_of_layers-1)*0.4 + 0.350)).step(0.4).each do |layer_height|
  puts "G92 E0.0"
  $extrude = 0.0
  puts "G1 Z#{layer_height}"
  make_square(10.0, 10.0, 80.0, layer_height)
end

last_normal_layer = (number_of_layers)*0.4+0.350
extra_layer = (number_of_layers+2)*0.4 + 0.350
(last_normal_layer..extra_layer).step(0.4).each do |layer_height|
  puts "G92 E0.0"
  $extrude = 0.0
  puts "G1 Z#{layer_height}"

  switch_temp(180)
  make_colored_squares(0, layer_height)
  switch_temp(230)
  make_colored_squares(1, layer_height)
end

puts
# Print footer code
footer.each {|code| puts code }
