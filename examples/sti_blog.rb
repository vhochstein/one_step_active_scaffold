require 'rubygems'
require 'fileutils'

puts "ActiveScaffold Department..."
puts %x[rails g active_scaffold Department name:string]

puts "ActiveScaffold Person.."
puts %x[rails g active_scaffold Person type:string name:string email:string balance:decimal report_to:integer department_id:integer]

puts "ActiveScaffold Employee.."
puts %x[rails g active_scaffold Employee]
inject_into_file('app/models/employee.rb', '\0' + "  belongs_to :boss, :class_name => 'Manager' , :foreign_key => :report_to\n  belongs_to :department\n", /ActiveRecord::Base\n/)
inject_into_file('app/models/employee.rb', 'Person', /ActiveRecord::Base/)

puts "ActiveScaffold Manager.."
puts %x[rails g active_scaffold Manager]
inject_into_file('app/models/manager.rb', 'Employee', /ActiveRecord::Base/)

puts "ActiveScaffold Customer.."
puts %x[rails g active_scaffold Customer]
inject_into_file('app/models/customer.rb', 'Person', /ActiveRecord::Base/)

puts "Delete STI Child migrations.."
Dir.glob("db/migrate/*create_{employees,managers,customers}.rb").each {|migration| FileUtils.rm(migration, :force => true) }
