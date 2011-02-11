require 'rubygems'

class File #:nodoc:

  unless File.respond_to?(:binread)
    def self.binread(file)
      File.open(file, 'rb') { |f| f.read }
    end
  end

end

def inject_into_file(inject_into, text, regex)
  content = File.binread(inject_into)
  content.gsub!(regex, text)
  File.open(inject_into, 'wb') { |file| file.write(content) }
end

JS_LIBS = ['prototype', 'jquery']
DATABASES = ['sqlite3', 'mysql', 'postgresl', 'oracle', 'frontbase', 'ibm_db']

if ARGV.length > 0
  if ['help', '-h', '?', '-?'].include? ARGV[0]
    puts "Usage: one_step_active_scaffold [app_name] [js_lib] [database] [db_user] [db_password]"
    puts "app_name   : name of your rails application ; default: howto"
    puts "js_lib     : valid Values: #{JS_LIBS.to_s}; default: prototype"
    puts "database   : valid values: #{DATABASES.to_s}; default: sqlite3"
    puts "db_user    : username for your db; default: <db_specific>"
    puts "db_password: pasword for your db user; default: ''"
    exit
  end
  rails_app = ARGV[0]
  js_lib = ARGV[1]
  database = ARGV[2]
  db_user = ARGV[3]
  db_password = ARGV[4]
end
rails_app ||= 'howto'
js_lib ||= 'prototype'
database ||= 'sqlite3'
db_user ||= nil
db_password ||= nil

raise unless JS_LIBS.include? js_lib
raise unless DATABASES.include? database

puts "Create new rails application #{rails_app} ..."
puts %x[rails new #{rails_app} -d #{database}]
Dir.chdir(rails_app)

inject_into_file('config/database.yml', "username: #{db_user}", /username:.*/) unless db_user.nil?
inject_into_file('config/database.yml', "password: #{db_password}", /password:.*/) unless db_password.nil?

puts "add activescaffold gem..."
begin
  %x[git --version]
  inject_into_file('Gemfile', '\0' + "gem 'render_component_vho', :git => 'git://github.com/vhochstein/render_component.git'\ngem 'active_scaffold_vho', :git => 'git://github.com/vhochstein/active_scaffold.git'\n", /Bundle the extra gems:\n/)
rescue
 #git not installed
  inject_into_file('Gemfile', '\0' + "gem 'active_scaffold_vho'\n", /Bundle the extra gems:\n/)
end

puts "Execute bundle install ..."
puts %x[bundle install]

puts "Create Database..."
system "rake db:create"

puts "Setup activescaffold using #{js_lib}..."
system "rails g active_scaffold_setup #{js_lib}"

#Create ActiveScaffolds

if(File.exist?('../model_setup.rb'))
  puts "Calling model_setup.rb"
  require '../model_setup.rb'
else
  puts "ActiveScaffold Team..."
  puts %x[rails g active_scaffold Team name:string position:integer]

  puts "ActiveScaffold Players..."
  puts %x[rails g active_scaffold Player name:string injured:boolean salary:decimal date_of_birth:date  team:references]
  inject_into_file('app/models/team.rb', '\0' + "  has_many :players\n", /ActiveRecord::Base\n/)
end


puts "Migrate Database..."
puts %x[rake db:migrate]
