# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


$ ->

  # Calls the server with a product and adds the result to the report
  loadProduct = (products, currentIndex) ->
    if currentIndex >= products.size()
      # THE END!
      $('input[type="submit"]').removeAttr 'disabled'

    else
      # Update current count
      $('.result-current-count').text "#{currentIndex + 1}"

      # Add a new line
      $result = $('<div></div>')
      $result.addClass 'result result-current'

      $resultHeader = $('<div></div>')
      $currentProduct = $(products[currentIndex])
      description = $currentProduct.parent().text()
      applicationName = $currentProduct.parents('fieldset').find('legend').text()
      $resultHeader.text "#{currentIndex + 1}. #{applicationName} - #{description}"
      $resultHeader.addClass 'result-header'
      
      $result.append $resultHeader

      $('.results').append $result

      # Returns an html table with orders on success
      jqxhr = $.ajax {
        url: "/product/#{products[currentIndex].name}",
        type: 'POST',
        timeout: 15000,
      }

      jqxhr.fail ->
        $result.addClass 'result-error'

      jqxhr.done (xhr, statusCode, jqxhr) ->
        unless jqxhr.status == 204

          $result.addClass 'result-success'
          $result.append xhr
          resultCount = $result.find('tr').size()
          $result.find('.result-orders').addClass 'collapsed'
          $resultHeader.text "#{$resultHeader.text()}: Found #{resultCount} results."
          $resultHeader.prepend '<span class="icon icon-plus-sign pull-right icon-large"></span>'
        else
          $result.addClass 'result-empty'
          $resultHeader.text "#{$resultHeader.text()}: No results found, sorry :("

      jqxhr.always ->
        $result.removeClass 'result-current'
        loadProduct products, currentIndex + 1

  # Change all checkboxes on selectAll click
  $('input[name="js-selectAll"]').on 'click', ->
    $('.options :checkbox').attr 'checked', $(this).is(':checked')

  # Change current application checkboxes on application click
  $('legend input[type="checkbox"]').on 'click', ->
    $applicationLegend = $(this)
    $parent = $(this).parents '.application'
    $parent.find('input[type="checkbox"]').attr 'checked', $(this).is(':checked')
 
  # Collapse or expand the current application on icon click
  $('legend .icon').on 'click', -> 
    $icon = $(this);
    $application = $icon.parents '.application'
    $application.toggleClass 'collapsed'
    $icon.toggleClass 'icon-plus-sign icon-minus-sign'

  # Collapse or expands a result orders on icon click
  $('.results').on 'click', '.icon', (event) ->
    $resultIcon = $(this) 
    $result = $resultIcon.parents '.result'
    $header = $resultIcon.parent() 
    $orders = $result.find '.result-orders'

    if $resultIcon.hasClass 'icon-plus-sign'
      $orders.slideDown 200, ->
        $orders.removeClass 'collapsed'
    else
      $orders.slideUp 200, ->
        $orders.addClass 'collapsed'
 
    $header.toggleClass 'expanded'
    $resultIcon.toggleClass 'icon-plus-sign icon-minus-sign'
    
  # Let the fun begin!!. Start loading products orders
  $('input[type="submit"]').on 'click', (event) ->
    event.preventDefault()

    # Clear the previous results and show the result counter
    $('.results').empty()
    $('.result-count').show()

    #Start loading all the results using ajax
    products = $('.products input:checkbox[checked]:not([name="js-selectAll"])')

    $('.result-total-count').text products.size()

    loadProduct products, 0
    $(this).attr 'disabled', ''
