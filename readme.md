# HTTP Negotiator

A HTTP content negotiator for V that allows you to parse the `Accept` header of an HTTP request and get the preferred response media type specified by the client.

## Usage/Examples

First, download the library:

```
v install --git https://github.com/gamemaker1/http-negotiator
```

Then use it:

```v
// Import the library
import gamemaker1.http_negotiator

// You need to get this value from the request object
// In this case, since it is an example, this value is hard-coded
// This value in an `Accept` HTTP header means that the client would like a
// response:
// - in the `application/json` format first
// - if that's not available, give it in the `text/plain` format
// - if that's not available, we're fine with anything
// The `q` paramter stands for `quality`, which indicates how much the client
// favours that response media type (0 is least, 1 is most; default is 1).
accept_header_value := 'application/json;charset=utf-8, text/plain;q=0.9;charset=utf-8, text/html;q=0.8;charset=utf-8, */*;q=0.7'
// Which media types you (the server) can respond in
possible_media_types := ['text/html', 'application/json']

// Now the library allows you to get:
// 1. a list of response media types in order of client's preference
// 2. the most preferred media type that the client wants

// For 1:
preferred_media_types := http_negotiator.get_media_types(
	// The `Accept` header passed by the client
	accept_header_value,
	// Valid media types that you can respond in
	possible_media_types
) or {
	// If:
	// - none of the client's accepted media types can be provided by the server
	// - a media type provided by the client is an invalid one
	// Then: use 'application/xml' by default
	'application/xml'
} // Returns ['application/json', 'text/html']

// For 2:
preferred_media_type := http_negotiator.get_media_type(
	// The `Accept` header passed by the client
	accept_header_value,
	// Valid media types that you can respond in
	possible_media_types
) or {
	// If:
	// - none of the client's accepted media types can be provided by the server
	// - a media type provided by the client is an invalid one
	// Then: use 'application/xml' by default
	'application/xml'
} // Returns 'application/json'
```

An example with VWeb can be found in [`examples/vweb.v`](/examples/vweb.v)

## Issues/Contributing

Thank you for using this library. Please feel free to open an issue to report a bug or suggest something. PRs are also welcome!

## License

This project is licensed under the ISC license. View the [license file](/license.md) for more details.

Copyright 2021 Vedant K (gamemaker1) \<gamemaker0042 at gmail dot com\>
