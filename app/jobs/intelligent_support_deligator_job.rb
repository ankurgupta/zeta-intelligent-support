class IntelligentSupportDeligatorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts args
    
    puts "***********"

    # Do something later
  end
end
