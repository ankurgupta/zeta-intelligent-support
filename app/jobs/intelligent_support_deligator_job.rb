class IntelligentSupportDeligatorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts args
    sleep 20
    puts "***********"

    # Do something later
  end
end
