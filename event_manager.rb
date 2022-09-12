require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/,'')
  if phone_number.length == 10
    phone_number
  elsif (phone_number.length == 11 && phone_number[0] == "1")
    phone_number[1..]
  else
    "Incorrect number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


calculate_weekday_by_number = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}
i = 0
hour_array = []
wday_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  regdate = row[:regdate]
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  time = DateTime.strptime(regdate, "%m/%d/%y %H:%M")

  hour_of_day = time.hour
  day_of_week = time.wday

  hour_array.push(hour_of_day)
  wday_array.push(day_of_week)

  i+=1

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

total = 0
hour_array.each do |item|
  total += item.to_i
end

puts "The most active hour is #{total / i}:00"

total = 0
wday_array.each do |item|
  total += item.to_i
end

puts "The most active day is #{calculate_weekday_by_number[total / i].capitalize}"



