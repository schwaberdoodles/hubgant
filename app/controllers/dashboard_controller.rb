class DashboardController < ApplicationController
  def index
    @repositories = Organization.repositories
  end
end