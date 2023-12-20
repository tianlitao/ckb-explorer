class ViewController < ActionController::Base
  layout 'application'
  before_action :set_i18n

  def set_i18n
    if params[:local].present? && params[:local].in?(['zh', 'en'])
      cookies[:local] = params[:local]
    end

    if cookies[:local].present? && cookies[:local].in?(['zh', 'en'])
      I18n.locale = cookies[:local].to_sym
    end
  end

end
