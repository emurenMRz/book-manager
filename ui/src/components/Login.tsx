import * as React from "react";
import { UserType } from "./context/UserType";
import { GET, POST, setCSRFToken } from "../utility";

export default function Login(props: { handleSucceed: Function }) {
	const refName = React.createRef<HTMLInputElement>();
	const refPass = React.createRef<HTMLInputElement>();
	const refNotice = React.createRef<HTMLDivElement>();

	const login = (json: { succeed: boolean, _csrf: string, userType: UserType, error: string }) => {
		if (json.error)
			throw json.error;

		if (!json.succeed)
			throw "セッションIDが取得できません";
		setCSRFToken(json._csrf);
		props.handleSucceed({ state: json.succeed, userType: json.userType });
	};

	const notice = (e: Error | string) => {
		if (typeof e == 'string' && refNotice && refNotice.current)
			refNotice.current.textContent = e;
		else
			console.error(e);
	};

	const handleLogin = () => {
		const name = refName.current?.value;
		const pass = refPass.current?.value;
		if (!name || !pass)
			return;

		POST("login", `id=${name}&pw=${pass}`)
			.then(r => r.json())
			.then(login)
			.catch(notice);
	};

	const handleDemo = () => {
		GET("demo")
			.then(r => r.json())
			.then(login)
			.catch(notice);
	};

	return (
		<div className="login-base">
			<form className="login" onSubmit={handleLogin}>
				<div className="title">蔵書管理</div>
				<div className="version">v2.0α</div>
				<input ref={refName} tabIndex={1} type="text" autoComplete="username" name="user_id" placeholder="アカウントID" />
				<input ref={refPass} tabIndex={2} type="password" autoComplete="current-password" name="user_passward" placeholder="パスワード" />
				<div ref={refNotice} className="notice"></div>
				<div className="button-group">
					<div tabIndex={3} className="button" onClick={handleLogin} onKeyDown={handleLogin}>ログイン</div>
				</div>
				<div className="button-option-group">
					<div className="button" onClick={handleDemo}>お試しログイン</div>
				</div>
			</form>
		</div>
	);
};
