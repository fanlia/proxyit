module main

import net.http
import vweb

struct App {
	vweb.Context
}

@['/p']
pub fn (mut app App) proxy() vweb.Result {
	url := app.query['url']
	method := match app.query['method'] {
		'post', 'POST' { http.Method.post }
		else { http.Method.get }
	}
	ua := app.req.header.get(.user_agent) or { '' }
	mut header := http.Header{}
	header.add(.user_agent, ua)
	data := app.query['data']
	options := http.FetchConfig{
		url: url,
		method: method,
		header: header,
		data: data,
	}
	res := http.fetch(options) or { return app.text(err.str()) }

	content_type_with_charset := res.header.get(.content_type) or { 'text/plain' }
	content_type := content_type_with_charset.split(';')[0]
	app.set_status(res.status_code, res.status_msg)
	app.send_response_to_client(content_type, res.body)
	return app.not_found()
}

fn main() {
	mut app := &App{}
	vweb.run(app, 8002)
}
