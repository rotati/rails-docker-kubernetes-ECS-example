class PagesController < ApplicationController
  def welcome
    greeting = "Hello from #{ENV['HOSTNAME']}"
    render json: {message: greeting}, status: 200
  end
end
