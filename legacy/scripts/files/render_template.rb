#!/usr/bin/env ruby

require 'erb'
require 'json'

# Execute users.sh to get user data (replace with actual command)
users_json = `./users.sh`

# Parse JSON data
users_data = JSON.parse(users_json)

# ERB template file
template_file = 'payroll.sql.erb'
erb_template = File.read(template_file)

# Create ERB instance
erb = ERB.new(erb_template)

# Bind data to the template
result = erb.result(binding)

# Output the rendered result to /tmp/payroll.sql
File.open('/tmp/payroll.sql', 'w') { |file| file.write(result) }

puts "Template rendered successfully to /tmp/payroll.sql"

