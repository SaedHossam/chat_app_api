class ApplicationsController < ApplicationController
    before_action :set_application, only: [:show, :update, :destroy]
  
    # GET /applications
    def index
      @applications = Application.all
      render json: @applications.map { |app| selected_attributes_for_application(app) }
    end
  
    # GET /applications/:token
    def show
      render json: selected_attributes_for_application(@application)
    end
  
    # POST /applications
    def create
      @application = Application.new(application_params)
  
      if @application.save
        render json: selected_attributes_for_application(@application), status: :created
      else
        render json: @application.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /applications/:token
    def update
      if @application.update(application_params)
        render json: selected_attributes_for_application(@application)
      else
        render json: @application.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /applications/:token
    def destroy
      @application.destroy
    end
  
    private
  
    # Use callbacks to share common setup or constraints between actions.
    def set_application
      @application = Application.find_by!(token: params[:token])
    end
  
    # Only allow a trusted parameter "white list" through.
    def application_params
      params.require(:application).permit(:name)
    end

    def selected_attributes_for_application(application)
      application.slice(:token, :name, :chats_count)
    end
end
