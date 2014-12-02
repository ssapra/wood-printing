# Constants
layer_height = 0.4
start_x = 50.0
start_y = 50.0
start_z = 0.350
feed_rate = 1400.00
extrude_amount = 0.0

# Set radius of sphere
radius = 20

prelude = ["G21", "M107", "M104 S200", "G28 X0 Y0", "G29", "M109 S200", "G90", "G92 E0", "M82"]
footer = ["G92 E0", "M107", "M104 S0", "G28 X0", "G28 Y0", "M84"]

# Print prelude code
prelude.each {|code| puts code }

skirt_radius = 40
# Printing skirt
puts "G1 X#{start_x} Y#{start_y}"
new_x = start_x - skirt_radius
circumference = (2*Math::PI*skirt_radius).round(4)
puts "G1 X#{new_x} Y#{start_y}"
extrude_amount += circumference.round(4)/10.0
puts "G2 I#{skirt_radius} E#{extrude_amount.round(4)}"

i = 0
# Print each layer
(start_z+radius..(start_z + 2*radius)).step(layer_height).each do |z_value|

  # Reset extrude amount
  extrude_amount = 0
  puts "G92 E#{extrude_amount}"
  puts "G1 Z#{z_value.round(4) - radius} F7800.000"

  # Calculate radius from circle equation
  radius_max = Math.sqrt(radius**2 - (z_value-radius-start_z)**2)

  if i % 2 == 0
    # Print concentric circles at each layer
    (0.4..radius_max).step(0.4).each do |radius|
      new_x = start_x - radius
      puts "G1 X#{new_x.round(4)} Y#{start_y.round(4)}"
      puts "G1 F#{feed_rate}"
      circumference = (2*Math::PI*radius)
      extrude_amount += circumference/10.0

      # Print arc command
      puts "G2 I#{radius.round(4)} E#{extrude_amount.round(4)}"
    end
  else
    new_x = start_x - radius_max
    puts "G1 X#{new_x.round(4)} Y#{start_y.round(4)}"
    puts "G1 F#{feed_rate}"
    circumference = (2*Math::PI*radius_max)
    extrude_amount += circumference/10.0

    # Print arc command
    puts "G2 I#{radius_max.round(4)} E#{extrude_amount.round(4)}"
  end
  i+=1

end

puts

# Print footer code
footer.each {|code| puts code }
