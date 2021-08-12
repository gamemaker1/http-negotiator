// A HTTP content negotiator for V

module http_negotiator

// Internal structs and functions

// `struct` to represent a media type
struct MediaType {
pub mut:
	// The category (e.g.: `text` or `application`)
	category string
	// The subcategory (e.g.: `plain`, `json`)
	subcategory string
	// The quality (e.g.: `0.6`, `0.8`) [default = 1]
	quality f32 = 1.0
}

fn (media_type MediaType) get_full_type() string {
	return '$media_type.category/$media_type.subcategory'
}

// `struct` to represent a negotiation error
struct NegotiationError {
	msg  string = 'Unexpected error'
	code int    = 1
}

// Parse a string and return a MediaType struct
fn parse_media_type_from_string(str string) ?MediaType {
	// In case there is a parameter following the media type; i.e.: 
	// application/json;q=0.8
	media_type_and_params := str.split(';').reverse()
	media_type := media_type_and_params.pop()
	mut params := media_type_and_params.clone()
	// The media type is the first part
	// Split the media type by the '/' so as to get the category (i.e.: `text`,
	// `application`, etc.) and subcategory (i.e.: `plain`, `json`, etc.)
	category_and_subcategory := media_type.split('/')
	// If there is no category and subcategory, the media type is invalid. PANIC!
	if category_and_subcategory.len != 2 {
		return IError(NegotiationError{
			msg: 'Invalid media type in header'
		})
	}

	// Get the `q` parameter, we don't care about the others - sorry others :(
	mut parsed_params := {
		'q': '1.0'
	}
	for key_value_pair in params {
		// Split the string based on the equal to
		// Ideally, this should not happen, but in case one of the values
		// contains an '=', then the part after that would get eaten up: hence
		// the elaborate reverse() then pop() then reverse() then join('=')
		mut key_and_val := key_value_pair.split('=').reverse()
		key := key_and_val.pop()
		key_and_val = key_and_val.reverse()
		val := key_and_val.join('=')

		parsed_params[key] = val.trim_space()
	}

	return MediaType {
		category: category_and_subcategory[0]
		subcategory: category_and_subcategory[1]
		quality: parsed_params['q'].f32()
	}
}

// Parse the header and return a list of media types, in order of quality
fn parse_accept_header(accept_header_value string) ?[]MediaType {
	// First, split the string by commas to get an array of media types and
	// associated parameters
	// Also remove blank elements from the resulting array and trim leading and
	// trailing blanks from all elements
	split_values := accept_header_value.split(',')
		.filter(it != '')
		.map(it.trim_space())
	// If the array is blank, no media types were specified
	if split_values.len == 0 {
		// Return a blank array
		return []
	}

	// Create an array to hold the parsed media types as structs
	mut media_types := []MediaType{}
	// Loop through the array of split-by-comma media types and convert them to
	// MediaType structs
	for value in split_values {
		media_types << parse_media_type_from_string(value)?
	}

	// Sort the media types based on quality (i.e.: client preference) (in case
	// of a tie, client provided order matters)
	media_types = media_types.reverse()
	media_types.sort(b.quality < a.quality)
	return media_types
}

// Public API

// Call `parse_accept_header`, and return only those which are mentioned in
// the preferred_types array, while maintaining the order returned by the
// `parse_accept_header` method
pub fn get_media_types(accept_header_value string, preferred_types []string) ?[]string {
	// First parse the header
	mut parsed_media_types := parse_accept_header(accept_header_value)?

	// Check if the first parsed types is */* OR the returned array is empty
	if parsed_media_types.len == 0 || '*/*' == parsed_media_types.map(it.get_full_type())[0] {
		return preferred_types
	}

	preferred_types_as_struct := preferred_types.map(fn (str string) MediaType {
		return parse_media_type_from_string(str) or {
			MediaType {
				category: str.split('/')[0]
				subcategory: str.split('/')[1]
			}
		}
	})

	// Loop through the preferred types and check if any of the parsed types match
	// If they do, add them to the media_types array
	// TODO: Filter doesn't work here, you can't reference variables outside a
	// custom filter function. Figure out why
	mut media_types := []MediaType{}
	for preferred_type in preferred_types_as_struct {
		for mut media_type in parsed_media_types {
			if media_type.category == preferred_type.category && (
				media_type.subcategory == preferred_type.subcategory
				|| media_type.subcategory == '*'
				|| preferred_type.subcategory == '*'
			) {
				if media_type.subcategory == '*' && media_type.category != '*' {
					media_type.subcategory = preferred_type.subcategory
				}
				media_types << media_type
			}
		}
	}

	// If none of them matched, and the parsed_media_types contains '*/*',
	// return the preferred types as is
	if media_types.len == 0 {
		for media_type in parsed_media_types {
			if media_type.get_full_type() == '*/*' {
				return preferred_types
			}
		}

		// Else if we are still with nothing, return an error
		return IError(NegotiationError{
			msg: 'No preferred response media type'
		})
	}
	
	// Sort the media types based on quality (i.e.: client preference) (in case
	// of a tie, client provided order matters)
	media_types = media_types.reverse()
	media_types.sort(b.quality < a.quality)
	return media_types.map(it.get_full_type())
}

// Call `get_media_types` and return the first value returned
pub fn get_media_type(accept_header_value string, preferred_types []string) ?string {
	filtered_media_types := get_media_types(accept_header_value, preferred_types)?
	return if filtered_media_types.len > 0 {
		filtered_media_types[0]
	} else {
		IError(NegotiationError{
			msg: 'No preferred response media type'
		})
	}
}
