# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

toggleSearchMode = () ->
	v = $('#search').val()
	
	if $('#search').val() == ''
		$('.large-logo').show()
		$('.small-logo').hide()
		$('#loading-search').hide()
	else
		$('.large-logo').hide()
		$('.small-logo').show()
		$('#loading-search').show()
		
search = (id) ->
	url = "/search/fetch?id=#{id}"
	req = $.get url
	req.success (html) ->
		display_results(html)
	req.error (jqXHR, status, error) ->
		display_error(error)
		
display_results = (html) ->
	$('#loading-search').hide()
	$('#search-results').html(html)
		
display_error = (error) ->
	$('#loading-search').hide()
	$('#search-results').html("<div class='alert'>#{error}</div>")
	
@resizeImage = (image, size) ->
	if image.height() > image.width()
		image.width(size)
	else
		image.height(size)
		l = (image.width() - size) / 2
		r = size + l
		image.css('clip', "rect(0px,#{r}px,#{size}px,#{l}px)")
		image.css('margin-left', "-#{l}px")
		
ready = ->
	$('#search').autocomplete({
		source: "/search/suggest.json",
		minLength: 2,
		focus: (event,ui) ->
			$('#search').val(ui.item.query)
			false
		select: (event,ui) ->
			$('#search-form').submit()
			false
	})
	.autocomplete('instance')._renderItem = (ul, item) ->
		l = $('#search').val().length
		str = item.query[0..l-1] + '<b>' + item.query[l..]
		$('<li>'+str+'</b></li>').appendTo(ul)
	if $('#search_query').val() == ''
		$('#search').val('')
	toggleSearchMode()

$(document).ready(ready)
$(document).on('page:load', ready)

$ ->
	$("img[data-loading='true']").load () ->
		id = $('#search_id').val()
		if id != ''
			search(id)