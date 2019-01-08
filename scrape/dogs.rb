require 'nokogiri'
require 'open-uri'
require 'rubygems'
require 'mechanize'
require 'csv'
require 'date'
require 'active_support'


#go to page
originalPage = "https://dogadoptions.franklincountyohio.gov/"
agent = Mechanize.new
page = Nokogiri::HTML(open("https://dogadoptions.franklincountyohio.gov/?viewAll=1&submit=Search"))

#create hashtable of the names and their websites
dogSites = Hash.new
dogs = page.css("div.col-md-3.dog").css("h2")
#create a hashtable for their individual information
info = Hash.new {|h,k| h[k] = [] }



#GET THE LINKS
 i=0
for pups in dogs do
	dogSites["#{pups.text}"] = originalPage + "#{dogs.css("a")[i]["href"]}"
	i+=1
end

#go through the links to get all of the needed info
for goodboys in dogs do
  #open links
	page= agent.get(dogSites["#{goodboys.text}"])
  #get the area where the bio is stored
  sort = page.search(".initial-content").children()[3].text
  #remove all of the html formatting garbage
  sort =sort.gsub(/[\t\r\n]+/,"")
  #get their narritives
  #if there is a narritive make a starting point for it
  if page.search(".initial-content").search(".col-xs-7").search("em")[0] != nil then
  start = page.search(".initial-content").search(".col-xs-7").search("em")[0].text
  end
  #if there are badges, make a stopping point for the narritive so we dont get a badge description
  if page.search(".initial-content").search(".col-xs-7").search("em")[1] != nil then
  stop =page.search(".initial-content").search(".col-xs-7").search("em")[1].text
  end
  #the narritive to sort through
  narritive = page.search(".initial-content").search(".col-xs-7").text.gsub(/[\t\r\n]+/,"")
  # get the info...
  #ID is assumed to be present for all dogs
  #set up hashtable with dog index to avoid duplicates
  #push their names, all dogs should have a name
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "#{goodboys.text}"
  #kennel
  if sort.index('Kennel:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Kennel:')+8...sort.index('ID')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Kennel Given"
  end

  #location
  if sort.index('Location:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Location:')+10... sort.index('Age')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Location Givem"
  end
  #age
  if sort.index('Age:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Age:')+5... sort.index('Breed:')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Age Given"
  end
  #breed
  if sort.index('Breed:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Breed:')+7... sort.index('Adult')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Breed Fiven"
  end
  #size
  if sort.index('Size:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Size:')+6... sort.index('Weight')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Size Given"
  end
  #weight
  if sort.index('Weight:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Weight:')+8... sort.index('Sex')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Weight Given"
  end
  #sex
  if sort.index('Sex:') != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Sex:')+5... sort.index('Adoption')]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Sex Given"
  end
  #adoption amount
  #i had to hard code this and I assumed the price would never exceed 1000
  if sort.index('Amount:') then
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << sort[sort.index('Amount:')+8,4]
  else
  info[sort[sort.index('ID:')+4... sort.index('Location')]] << "No Price Given"
  end
  #badges, array form so they stay in the same row
  badges = []
  for items in page.search(".icon").search(".icon-name").children() do
   badges <<items.text
  end
    info[sort[sort.index('ID:')+4... sort.index('Location')]] <<badges

    #for the weird bios
    if page.search(".initial-content").search(".col-xs-7").search("em")[1] == nil then
      filler = "#{(narritive.slice start)}"
      if start.include? "#{goodboys.text}" then

    info[sort[sort.index('ID:')+4... sort.index('Location')]]<<  start + filler
  end
  if filler.include? "#{goodboys.text}" then
    info[sort[sort.index('ID:')+4... sort.index('Location')]]<<  start + filler
  end

  end


    #if there is no bio
    if page.search(".initial-content").search(".col-xs-7").search("em")[0] == nil then
    info[sort[sort.index('ID:')+4... sort.index('Location')]]<<  ""
  end
#narritives minus the badge description
  if page.search(".initial-content").search(".col-xs-7").search("em")[1] != nil then
  info[sort[sort.index('ID:')+4... sort.index('Location')]]<<  narritive[narritive.index(start)... narritive.index(stop)]
end
  #for the long narritivies
if start.length>45  then
info[sort[sort.index('ID:')+4... sort.index('Location')]]<<  start + " " + narritive
end

  #sleep so website doesnt crash
	sleep 1
end


#create/open the csv file then write info to it
CSV.open("#{File.absolute_path('DogInfo.csv')}", 'a+') do |csv|
  csv << ["Date, Time", "ID #", "Name", "Kennel", "Location", "Age", "Breed", "Adult Size", "Sex","Weight", "Adoption Price", "Badges", "Narritive"]
   info.each_key do |key|
    #time, dog info
    csv << [Time.now,"#{key}",info["#{key}"][0],info["#{key}"][1],info["#{key}"][2],info[key][3],info[key][4],info[key][5],
    info[key][6],info[key][7],info[key][8],info[key][9],info[key][10]]
end
end

#this is for the daily scrapping as sort of a log book to ensure its happening everyday
puts "Site visited at #{Time.now}"
