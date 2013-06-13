class PagosMovistarController < ApplicationController

  def index
    #Load all logins
    @options = {}

    File.read('logins.csv').each_line do |line|
      values = line.split(';')
      if values.length != 5
        raise Exception( 'Each row must have 5 values: application, description, productCode, username and password')
      end
      # Each record in options represents an application, each having an array of products
      key = values[0].titleize.to_sym
      @options[ key ] ||= []
      @options[ key ] << { description: "#{values[1]} - #{values[2]}", name: values[3] }

    end

    @options = @options.sort

  end

  def report

    @base_url = 'ultra secret url'

    login = { userName: '<username>', password: '*******' }

    login_results = login(login)


    if login_results[:success]

      parameters = {
        # Parameters used in the http calls
      }


      # TODO: Add dates based on user selection, giving the last month as sensible default range
      current_time = DateTime.now
      past_month = current_time << 1

      %w(Year Month Day Time).each do |part|
        eval("parameters[\"from#{part}\"] = past_month.#{part == "Time" ? "hour" : part.downcase}")
        eval("parameters[\"to#{part}\"] = current_time.#{part == "Time" ? "hour" : part.downcase}")
      end

      @results = get_purchase_records(login[:userName], login_results[:session_id], parameters)

      puts " has #{@results.length} results"

      unless @results.empty?
        render layout: false
      else
        render nothing: true, status: 204
      end

    end
  end

  private

  def login(login_parameters)

    session_id = ''
    response = RestClient.post("<loginUrl>", login_parameters) { |response, request, result, &block|

      if [301, 302, 307].include? response.code
        session_id = response.cookies["JSESSIONID"]
        response.follow_redirection(request, result, &block)
      else
        response.return!(request, result, &block)
      end

    }

    { success: (response.code == 200), session_id: session_id }
  end

  def get_purchase_records(name, session_id, parameters)

    response = RestClient.get("<reportGenerationUrl>", params: parameters, cookies: {JSESSIONID: session_id})

    [] if response.to_str.include? 'No se hallaron resultados'

    doc = Nokogiri::HTML.parse(response.to_str)
    results = []
    doc.css('td.globalHeaderH table tr.globalContent').each do |row|
      row_array = []

      #Iterate over all the results to create an array of results
      row.css('td:not(.globalContent)').each_with_index do |column, index|
        # Replace with gsub
        column = column.text
        column.gsub!(/\t|\r|\n|\u00A0/, '')
        column.strip!

        # "+Info" is a link, so its text returns nil. Discard it
        unless index == 0 || !column || column == '+Info'
          row_array << column
        end
      end

      (results << row_array) unless row_array.empty?
    end
    results
  end

end
