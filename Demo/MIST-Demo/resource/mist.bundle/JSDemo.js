require('MistJSHttpRequestHelper, MistJSToast')

function getWeather(city) {
	var http = MistJSHttpRequestHelper.sharedInstance()
	var url = 'http://api.openweathermap.org/data/2.5/weather?q=' + city.toJS() + '&appid=e29037c971eb05e99323a39106735690&units=metric&lang=zh'
	http.get_handler(url, block('NSDictionary *, NSError *', function(response, error) {
		var res = response.toJS()
		MistJSToast.alert_content('Result', [res.name, res.weather[0].description, res.main.temp].join(', '))
	}))
}

global.export(getWeather)