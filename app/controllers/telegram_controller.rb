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
      one_time_keyboard: true,
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
        one_time_keyboard: true,
        selective: true
      }
    else
      save_context :address
      respond_with :message, text: 'Я не знаю где это, выбери филиал из списка 😂'
    end
  end

  def service(*args)
    if args.any?
      save_context :barber
      service_name = args.join ' '
      service = services.select { |e| "#{e['title']} — #{e['price_min']}₽" == service_name }.first
      session[:service_id] = service['id']
      respond_with :message, text: "#{service['title']}, хорошо 👌🏻", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: 'Кому доверим своё самое ценное?', reply_markup: {
        keyboard: barbers_names,
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true
      }
    else
      save_context :service
      respond_with :message, text: 'Эм, мы такое не делаем 🤷🏻‍♂️'
    end
  end

  def barber(*args)
    if args.any?
      save_context :date
      barber_name = args.join ' '
      barber = barbers.select { |e| e['name'] == barber_name }.first
      session[:barber_id] = barber['id']
      respond_with :message, text: "#{barber['name']} красавчик, поддерживаю 🤘🏻", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: 'В какой день зайдёшь?', reply_markup: {
        keyboard: date_names,
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true
      }
    else
      save_context :barber
      respond_with :message, text: 'Это кто? 😦'
    end
  end

  def date(*args)
    if args.any?
      save_context :time
      date_name = args.join ' '
      date = dates.select { |e| Date.parse(e).strftime('%e %B, %A') == date_name }.first
      session[:date] = date
      respond_with :message, text: "Отлично, #{date_name} идеально", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: 'Свободного времени не так много, давай подберём удобное для тебя', reply_markup: {
        keyboard: time_names,
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true
      }
    else
      save_context :date
      # respond_with :message, text: 'Что-то не получается в этот день, давай выберем что-то другое'
    end
  end

  def time(*args)
    if args.any?
      save_context :finish
      time_name = args.join ' '
      time = times.select { |e| e['time'] == time_name }.first
      session[:time] = time
      respond_with :message, text: "Приходи ровно в #{time_name}, не опаздывай", reply_markup: {
        remove_keyboard: true
      }
      respond_with :message, text: 'Для записи нужен номер твоего мобильного', reply_markup: {
        keyboard: [[{ text: 'Звони на этот мобильный', request_contact: true }]],
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true
      }
    else
      save_context :time
      respond_with :message, text: 'Что-то не получается в это время, давай выберем что-то другое'
    end
  end

  def finish(*)
    respond_with :message, text: 'Мы наберём тебе, до встречи 👋🏻', reply_markup: {
      remove_keyboard: true
    }
  end

  private

  def locations
    response = Faraday.get 'https://n87731.yclients.com/api/v1/companies/?group_id=15&count=1000&forBooking=1',
                           nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
    JSON.parse response.body
  end

  def location_names
    locations.map { |e| [e['title']] }
  end

  def services
    response = Faraday.get "https://n87731.yclients.com/api/v1/book_services/#{session[:branch_id]}?staff_id=&datetime=&bookform_id=87731",
                           nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
    JSON.parse(response.body)['services']
  end

  def service_names
    services.map { |e| ["#{e['title']} — #{e['price_min']}₽"] }
  end

  def barbers
    response = Faraday.get "https://n87731.yclients.com/api/v1/book_staff/#{session[:branch_id]}?service_ids%5B%5D=#{session[:service_id]}&datetime=&without_seances=1",
                           nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
    JSON.parse(response.body).select { |e| e['bookable'] }
  end

  def barbers_names
    barbers.map { |e| [e['name']] }
  end

  def dates
    response = Faraday.get "https://n87731.yclients.com/api/v1/book_dates/#{session[:branch_id]}?service_ids%5B%5D=#{session[:service_id]}&staff_id=#{session[:barber_id]}",
                           nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
    JSON.parse(response.body)['booking_dates']
  end

  def date_names
    dates.map { |e| [Date.parse(e).strftime('%e %B, %A')] }
  end

  def times
    response = Faraday.get "https://n87731.yclients.com/api/v1/book_times/#{session[:branch_id]}/#{session[:barber_id]}/#{session[:date]}?service_ids%5B%5D=#{session[:service_id]}",
                           nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
    JSON.parse response.body
  end

  def time_names
    times.map { |e| [e['time']] }
  end
end
