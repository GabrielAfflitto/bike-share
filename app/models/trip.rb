require 'pry'
class Trip < ActiveRecord::Base

  belongs_to :station, foreign_key: "start_station_id", class_name: "Station"
  # belongs_to :end_station, foreign_key: "end_station_id", class_name: "Station"

  validates_presence_of :duration,
                        :start_date,
                        :start_station_name,
                        :start_station_id,
                        :end_date,
                        :end_station_name,
                        :bike_id,
                        :subscription_type


  def self.average_trip_length
    average(:duration).to_i
  end

  def self.longest_ride
    maximum(:duration).to_i
  end

  def self.shortest_ride
    minimum(:duration).to_i
  end

  def self.station_with_most_rides_at_start
      max = group(:start_station_id).order("count_id DESC").count(:id).first[0]
      Station.find(max).name
  end

  def stations
    Station.find(params[:id])
  end

  def self.number_of_rides_started_at_this_station(stations)
    all_station_id = group(:start_station_id).order("count_id DESC").count(:id)
    all_station_id.find do |trip_id, station_id|
      if trip_id == stations
        station_id
      end
    end
  end

  def self.number_of_rides_ended_at_this_station(stations)
    all_station_id = group(:end_station_id).order("count_id DESC").count(:id)
    all_station_id.find do |trip_id, station_id|
      if trip_id == stations
        station_id
      end
    end
  end

  def self.station_with_most_rides_at_end
    max = group(:end_station_id).order("count_id DESC").count(:id).first[0]
    Station.find(max).name
  end

  def self.years
    distinct.pluck('extract(year from start_date)')
  end

  def self.find_month_names(month)
    Date::MONTHNAMES[month]
  end

  def self.trips_per_month
    years.map do |year|
      found = where('extract(year from start_date)= ?', year).group('extract(month from start_date)').order("count_id DESC").count(:id)
      months = Hash[found.map{|month,count|[month.to_i,count]}]
      month_names = Hash[months.map{|month,count|[find_month_names(month),count]}]
      {year => month_names }
    end
  end

  def self.sum_trips_per_year
    result = years.map do |year|
    found = where('extract(year from start_date)= ?', year).group('extract(month from start_date)').order("count_id DESC").count(:id)
    end
    result = result.map {|result| result.values.sum}
    years.zip(result)
  end

  def self.most_ridden_bike
    group(:bike_id).order("count_id DESC").count(:id).first
  end

  def self.least_ridden_bike
    group(:bike_id).order("count_id ASC").count(:id).first
  end


  def self.percentage_of_subscriber_type
    amount = subscription_type_breakout.values
    total = amount.sum
    amount.map do |num|
      ((num/total.to_f)*100).round(1)
    end
  end

  def self.subscription_type_breakout
     group(:subscription_type).order("count_id DESC").count(:id)
  end

  def self.date_with_most_trips
      counts = Hash.new(0)
     date = group(:start_date).order("count_id DESC").count(:id)
     all_dates = date.keys.map {|date|date.strftime("%m-%d-%y")}
     all_dates.each do |date|
       counts[date]+=1
     end
     counts.max_by {|k, v| v}
  end

  def self.date_with_least_trips
      counts = Hash.new(0)
     date = group(:start_date).order("count_id DESC").count(:id)
     all_dates = date.keys.map {|date|date.strftime("%m-%d-%y")}
     all_dates.each do |date|
       counts[date]+=1
     end
     counts.min_by {|k, v| v}
     #look for active record method with this same functionality
  end

  def self.most_frequent_destination(station)
    stations = where(start_station_id: station).group(:end_station_id).order('count_id DESC').count(:id).first
    Station.find(stations[0])[:name]
  end

  def self.most_frequent_origination(station)
    stations = where(end_station_id: station).group(:start_station_id).order('count_id DESC').count(:id).first
    Station.find(stations[0])[:name]
  end
end
