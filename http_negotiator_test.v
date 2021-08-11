// Tests for the http_negotiator module

module http_negotiator

const (
	test_accept_header_value = 'application/json;charset=utf-8, text/plain;q=0.3;charset=utf-8, image/*;q=0.7, application/vnd.github.preview-groot;q=0.4'
	test_preferred_headers = ['application/vnd.github.preview-groot', 'image/png', 'text/plain']
)

fn test_get_media_types()? {
	assert get_media_types(
		test_accept_header_value,
		test_preferred_headers,
	)? == ['image/png', 'application/vnd.github.preview-groot', 'text/plain']
}

fn test_get_media_type()? {
	assert get_media_type(
		test_accept_header_value,
		test_preferred_headers,
	)? == 'image/png'
}
