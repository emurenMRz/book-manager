export type token = string | null;

const G = {
	csrfToken: null as token,
};

const do_api = (api: string, method: string, body?: string) =>
	fetch(`api/${api}`, {
		method,
		headers: {
			"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
			"X_CSRF_TOKEN": G.csrfToken as string
		},
		body
	});

export function setCSRFToken(token: token = null) { G.csrfToken = token; }

export function GET(api: string) { return fetch(`api/${api}`); }
export function POST(api: string, body: string) { return do_api(api, "POST", body); }
export function PUT(api: string, body: string) { return do_api(api, "PUT", body); }
export function PATCH(api: string, body: string) { return do_api(api, "PATCH", body); }
export function DELETE(api: string) { return do_api(api, "DELETE"); }
(window as any).DELETE = DELETE;
