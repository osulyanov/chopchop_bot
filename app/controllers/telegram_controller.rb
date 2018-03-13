class TelegramController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

  def start(*)
    greetings = from ? "Привет, #{from['first_name']}!" : 'Привет!'
    respond_with :message, text: greetings
    respond_with :message, text: "Отлично выглядишь!\r\nБудешь ещё лучше, если мы немного освежим тебе стрижку 💇🏻‍♂️"
    save_context :enroll
    respond_with :message, text: 'Где тебе будет удобнее к нам заскочить?', reply_markup: {
      keyboard: [[{ text: 'Ближайший ко мне', request_location: true }]] + locations,
      resize_keyboard: true,
      selective: true
    }
  end

  def enroll(*args)
    if args.any?
      branch_name = args.join ' '
      respond_with :message, text: "Выбрал #{branch_name}", reply_markup: {
        remove_keyboard: true
      }
    else
      save_context :enroll
      respond_with :message, text: 'Я не знаю где это, выбери из списка 😂'
    end
  end

  private

  def locations
    @locations ||= begin
      response = Faraday.get 'https://n87731.yclients.com/api/v1/companies/?group_id=15&count=1000&forBooking=1',
                             nil, authorization: "Bearer #{Rails.application.secrets.yclients_token}"
      JSON.parse(response.body).map { |e| [e['title']] }
    end
  end
end
