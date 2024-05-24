class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    private

    def record_not_found(exception)
      model = exception.model.constantize.model_name.human
      render json: { error: "#{model} not found" }, status: :not_found
    end
end
