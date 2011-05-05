require 'rubygems'
require 'fileutils'

puts "ActiveScaffold AppLog..."
puts %x[rails g active_scaffold AppLog message:text]
Dir.glob("db/migrate/*create_app_logs.rb").each do|migration|
  inject_into_file(migration, '\0' + "      t.references :logable, :polymorphic => true\n", /t.text :message\n/)
end
inject_into_file('app/models/app_log.rb', '\0' + "  belongs_to :logable, :polymorphic => true\n\n  def to_label\n    \"#\{logable.class.human_name\}_Log_#\{id.inspect\}\"\n  end\n", /ActiveRecord::Base\n/)

puts "ActiveScaffold Invoices.."
puts %x[rails g active_scaffold Invoice no:string document_date:date]
inject_into_file('app/models/invoice.rb', '\0' + "  has_many :logs, :as => :logable, :class_name => 'AppLog', :dependent => :delete_all\n\n   def to_label\n    \"No. #\{self.no\}\"\n   end\n", /ActiveRecord::Base\n/)
