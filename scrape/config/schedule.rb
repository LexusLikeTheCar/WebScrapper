

set :output, "#{File.absolute_path("file.log")}"
# set :environment, 'develeopment'

every :day, :at => ['9:00 am','9:10 am'] do
 command "ruby #{File.absolute_path("dogs.rb")}"

end
