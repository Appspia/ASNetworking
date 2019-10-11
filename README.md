# ASNetworking

Simple Swift Networking Package

## Usage
```ruby

// API Definition
let api: API = .development

enum API: ASNetworking {
	// Example for Server Type
	case development
	case production

	var baseUrl: String {
		switch self {
		case .development:
			return "https://rss.itunes.apple.com"
		case .production:
			return "https://rss.itunes.apple.com"
		}
	}
}

extension API {
	// Top Podcasts List 
	func topPodcasts(countryCode: String, count: Int) -> ASHttpResponse<Podcasts> {
		let requestData = ASRequestData(urlString: baseUrl + "/api/v1/\(countryCode)/podcasts/top-podcasts/all/\(count)/explicit.json", httpMethod: .get)
		return httpRequest(requestData: requestData)
	}
}


// API usage example
func testApi() {
	api.topPodcasts(countryCode: "us", count: 100).response { result in
		switch result {
		case .success(let item):
			// Do somthing for success
		case .failure:
			// Do somthing for failure
		}
	}
}

```

## Author

Appspia, appspia@gmail.com

## License

ASNetworking is available under the MIT license. See the LICENSE file for more info.
