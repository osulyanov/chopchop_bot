class TelegramController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

  def start(*)
    greetings = from ? "Привет, #{from['first_name']}!" : 'Привет!'
    respond_with :message, text: greetings
    respond_with :message, text: "Отлично выглядишь!\r\nБудешь ещё лучше, если мы немного освежим тебе стрижку 💇🏻‍♂️"
    save_context :address
    respond_with :message, text: 'Где тебе будет удобнее к нам заскочить?', reply_markup: {
      keyboard: [[{ text: 'Ближайший ко мне', request_location: true }]] + location_names,
      resize_keyboard: true,
      selective: true
    }
  end

  def address(*args)
    if args.any?
      branch_name = args.join ' '
      branch = locations.select { |e| e['title'] == branch_name }.first
      session[:branch_id] = branch['id']
      respond_with :message, text: "#{branch_name} это отличный выбор!", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: "Адрес: #{branch['address']}"
      respond_with :message, text: "Телефон: #{branch['phone']}"
      respond_with :message, text: 'Что делать будем?', reply_markup: {
        keyboard: service_names(session[:branch_id]),
        resize_keyboard: true,
        selective: true
      }
    else
      save_context :enroll
      respond_with :message, text: 'Я не знаю где это, выбери филиал из списка 😂'
    end
  end

  private

  def locations
    @locations ||= begin
      response = Faraday.get 'https://n87731.yclients.com/api/v1/companies/?group_id=15&count=1000&forBooking=1',
                             nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
      JSON.parse response.body
    end
  end

  def location_names
    locations.map { |e| [e['title']] }
  end

  def services(branch_id)
    @services ||= []
    @services[branch_id] ||= begin
      response = Faraday.get "https://n87731.yclients.com/api/v1/book_services/#{branch_id}?staff_id=&datetime=&bookform_id=87731",
                             nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
      JSON.parse(response.body)['services']
    end
  end

  def service_names(branch_id)
    services(branch_id).map { |e| ["#{e['title']} — #{e['price_min']}₽"] }
  end
end
