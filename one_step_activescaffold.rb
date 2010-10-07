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


def configure_mysql(rails_app, db_user, db_password)
  inject_into_file('config/database.yml', config, /#{environment}:.*?5000/m)
  ['development', 'test', 'production'].each do |environment|
    config = MYSQL_CONFIG.sub(/{rails_app}/, rails_app).gsub(/{environment}/, environment).sub(/{db_user}/, db_user).sub(/{db_password}/, db_password)
    
  end
end

def configure_postgres(rails_app, db_user, db_password)
  inject_into_file('Gemfile', "gem 'mysql2'\n" + '\0', /\z/)
  ['development', 'test', 'production'].each do |environment|
    config = POSTGRES_CONFIG.sub(/{rails_app}/, rails_app).gsub(/{environment}/, environment).sub(/{db_user}/, db_user).sub(/{db_password}/, db_password)
    inject_into_file('config/database.yml', config, /#{environment}:.*?5000/m)
  end
end


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

puts "Execute bundle install ..."
puts %x[bundle install]

puts "Create Database..."
system "rake db:create"

puts "Download activescaffold plugin..."
puts %x[rails plugin install git://github.com/vhochstein/active_scaffold.git]

puts "Setup activescaffold using #{js_lib}..."
system "rails g active_scaffold_setup #{js_lib}"

#Create ActiveScaffolds
puts "ActiveScaffold Team..."
puts %x[rails g active_scaffold Team name:string position:integer]

puts "ActiveScaffold Players..."
puts %x[rails g active_scaffold Player name:string injured:boolean salary:decimal date_of_birth:date  team:references]
inject_into_file('app/models/team.rb', '\0' + "  has_many :players\n", /ActiveRecord::Base\n/)

puts "Migrate Database..."
puts %x[rake db:migrate]
