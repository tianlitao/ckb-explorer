class ViewController < ActionController::Base
  layout 'application'
  before_action :set_i18n

  def set_i18n
    if params[:local].present? && params[:local].in?(['zh', 'en'])
      I18n.locale = params[:local].to_sym
    end
  end

end
