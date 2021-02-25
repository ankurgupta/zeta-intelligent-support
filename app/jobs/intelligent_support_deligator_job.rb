class IntelligentSupportDeligatorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts args

    # Do something later
  end
end
