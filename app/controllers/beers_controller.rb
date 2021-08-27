class BeersController < ApplicationController
  before_action :authenticate!

  def index
    # https://lostisland.github.io/faraday/usage/
    # https://punkapi.com/documentation/v2

    beers_endpoint = 'https://api.punkapi.com/v2/beers'

    response = Faraday.get beers_endpoint

    if response.status == 200
      beers = JSON.parse response.body
      filtered_beers = filter_beers(beers, filter_params)

      beers_with_relevant_information = []
      if filtered_beers.present?
        filtered_beers.each do |beer|
          api_id = beer['id']

          beers_with_relevant_information << show_relevant_information(beer)
        end
      end

      render json: beers_with_relevant_information

    else
      render json: { message: 'error', status: response.status }, status: response.status
    end
  end

  def show
    api_id = permitted_params[:api_id]
    raise ActiveRecord::RecordNotFound if api_id.nil?

    beer_endpoint = "https://api.punkapi.com/v2/beers/#{api_id}"

    response = Faraday.get beer_endpoint

    if response.status == 200
      response_body = JSON.parse response.body
      response_beer = response_body.first
      api_id = response_beer['id']

      add_beer_to_database(api_id)

      beer = show_relevant_information(response_beer)

      render json: beer, status: :ok
    else
      render json: { message: 'error', status: response.status }, status: response.status
    end
  end

  def choose_favorite
    api_id = permitted_params[:api_id]
    Beer.where(user: @current_user).update_all(favorite: false)
    Beer.where(user: @current_user, api_id: api_id).update_all(
      favorite: true
    )
    render json: { message: 'You have chosen your favorite beer!' }, status: :ok
  end

  private

  def show_relevant_information(beer)
    api_id = beer['id']
    stored_beer = Beer.find_by(api_id: api_id, user_id: @current_user.id)

    {
      id: api_id,
      name: beer['name'],
      tagline: beer['tagline'],
      description: beer['description'],
      abv: beer['abv'],
      seen_at: stored_beer.present? ? stored_beer.seen_at : '',
      favorite: stored_beer.present? ? stored_beer.favorite : false
    }
  end

  def add_beer_to_database(api_id)
    return if Beer.exists?(api_id: api_id)

    Beer.create!(
      api_id: api_id,
      seen_at: Time.now,
      user: @current_user
    )
  end

  def filter_beers(beers, params)
    name = params[:name]
    beers = beers.select { |beer| beer['name'].include? name } if name.present?
    beers = beers.select { |beer| beer['abv'].to_d == params[:abv].to_d } if params[:abv].present?
    beers
  end

  def filter_params
    params.permit(:name, :abv)
  end

  def permitted_params
    params.permit(:api_id)
  end
end
