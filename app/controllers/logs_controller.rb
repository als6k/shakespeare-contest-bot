class LogsController < ActionController::Base
  include Pagy::Backend

  def index
    @pagy, @logs = pagy_countless(Log.order(id: :desc), items: 30)
  end
end
