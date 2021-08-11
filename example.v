// Example with VWeb

module main

// Imports
import vweb
import gamemaker1.http_negotiator

pub struct App {
	vweb.Context
}

[get]
['/names']
pub fn (mut app App) get_names_of_languages() vweb.Result {
	// Check what format the client wants the response in
	preferred_media_type := http_negotiator.get_media_type(
		// The `Accept` header passed by the client; defaults to '*/*', which means anything is fine
		app.req.header.get(.accept) or { '*/*' },
		// Valid media types that you are willing to respond in (in order of preference)
		['text/plain', 'text/html', 'application/json'],
	) or {
		// If there is no valid media type OR a media type provided by the client
		// is an invalid one, use 'text/html' by default
		'text/html'
	}

	// Return the list of languages in various formats
	match preferred_media_type {
		'text/plain' {
			return app.text('V, Go, Oberon, Rust, Swift, Kotlin, and Python')
		}
		'text/html' {
			return app.html('<ul><li>V</li> <li>Go</li> <li>Oberon</li> <li>Rust</li> <li>Swift</li> <li>Kotlin</li> <li>Python</li></ul>')
		}
		'application/json' {
			return app.json('{"languages":["V", "Go", "Oberon", "Rust", "Swift", "Kotlin", "Python"]}')
		}
		else {
			// NOTE: Should not happen (the `or` block above should set the preferred
			// media type to `text/html` in case any error occurs)
			app.set_status(406, 'Not Acceptable')
			return app.ok('Invalid response media type $preferred_media_type specified in `Accept` header')
		}
	}
}

fn main() {
	vweb.run<App>(App{}, 8000)
}
