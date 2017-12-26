class PagesController < ApplicationController
  def welcome
    hostname = `hostname`.strip
    greeting = "Hello from #{hostname}"
    render json: {message: greeting}, status: 200
  end
end
