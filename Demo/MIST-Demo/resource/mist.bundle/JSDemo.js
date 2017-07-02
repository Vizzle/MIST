function getWeather() {
	var url = 'http://api.openweathermap.org/data/2.5/weather?q=Hangzhou&appid=e29037c971eb05e99323a39106735690&units=metric&lang=zh'
	http.get(url, function(response, error) {
		toast.alert('Result', [response.name, response.weather[0].description, response.main.temp].join(', '))
	})
}