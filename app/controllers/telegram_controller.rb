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
      save_context :service
      branch_name = args.join ' '
      branch = locations.select { |e| e['title'] == branch_name }.first
      session[:branch_id] = branch['id']
      respond_with :message, text: "#{branch_name} это отличный выбор!", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: "Адрес: #{branch['address']}"
      respond_with :message, text: "Телефон: #{branch['phone']}"
      respond_with :message, text: 'Что делать будем?', reply_markup: {
        keyboard: service_names,
        resize_keyboard: true,
        selective: true
      }
    else
      save_context :address
      respond_with :message, text: 'Я не знаю где это, выбери филиал из списка 😂'
    end
  end

  def service(*args)
    if args.any?
      save_context :service
      service_name = args.join ' '
      service = services.select { |e| "#{e['title']} — #{e['price_min']}₽" == service_name }.first
      session[:service_id] = service['id']
      respond_with :message, text: "#{service['title']}, хорошо 👌🏻", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: 'Кому доверим своё самое ценное?', reply_markup: {
        keyboard: barbers_names,
        resize_keyboard: true,
        selective: true
      }
    else
      save_context :service
      respond_with :message, text: 'Эм, мы такое не делаем 🤷🏻‍♂️'
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

  def services
    @services ||= []
    @services[session[:branch_id]] ||= begin
      response = Faraday.get "https://n87731.yclients.com/api/v1/book_services/#{session[:branch_id]}?staff_id=&datetime=&bookform_id=87731",
                             nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
      JSON.parse(response.body)['services']
    end
  end

  def service_names
    services.map { |e| ["#{e['title']} — #{e['price_min']}₽"] }
  end

  def barbers
    @barbers ||= []
    @barbers[session[:branch_id]] ||= []
    @barbers[session[:branch_id]][session[:service_id]] ||= begin
      response = Faraday.get "https://n87731.yclients.com/api/v1/book_staff/#{session[:branch_id]}?service_ids%5B%5D=#{session[:service_id]}&datetime=&without_seances=1",
                             nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
      JSON.parse(response.body).select { |e| e['bookable'] }
    end
  end

  def barbers_names
    barbers.map { |e| [e['name']] }
  end
end
