_ = require('underscore')
cheerio = require('cheerio')
request = require('request-promise')
q = require('q')
fs = require('fs')

makeRandom = -> Math.random().toString(36).substring(7);

pageUrl = process.argv[2]
folder = process.argv[3] || makeRandom()

fs.mkdirSync(folder)
fs.mkdirSync(folder + "/resources")

treatUrl = do (pageUrl) ->
	(url) ->
		if !url?
			return null
		if url[0..1] == '//'
			return "http:#{url}"
		if url[0] == '/'
			return pageUrl + url
	

request(process.argv[2]).then (body) ->
	$ = cheerio.load(body)
	promises = $('script,link,img').map (index, element) ->
		$element = $(element)
		url = treatUrl($element.attr('src') || $element.attr('href'))
		return unless url
		name = makeRandom() + '__' + _.last(url.split('/'))
		refLocation = "resources/#{name}"
		fileLocation = "#{folder}/#{refLocation}"
		fs.writeFile(fileLocation, body)
		if $element.attr('src')
			$element.attr('src', refLocation)
		if $element.attr('href')
			$element.attr('href', refLocation)
		request(url).pipe(fs.createWriteStream(fileLocation))
	q.all(promises).then ->
		fs.writeFile("#{folder}/index.html", $.html())		
