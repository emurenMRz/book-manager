import "./css/style.scss";
import * as React from "react";
import * as ReactDOM from "react-dom";
import { GET, setCSRFToken } from "./utility";

import { UserType, UserTypeContext } from "./components/context/UserType";
import { ContentStatus, ContentStatusContext } from "./components/context/ContentStatus";
import { DisplayType, DisplayTypeContext } from "./components/context/DisplayType";

import Login from "./components/Login";
import Header from "./components/header/Header";
import Contents from "./components/contents/Contents";

import * as BookList from "./components/contents/BookList";

const App = (props: { loggedIn: boolean, userType: UserType }) => {
	const [loginData, setLoginData] = React.useState({ state: props.loggedIn, userType: props.userType });
	const [status, setStatus] = React.useState({ mode: "BookList", dataType: BookList.DataType.ToBuyList } as ContentStatus);
	const [displayType, setDisplayType] = React.useState(DisplayType.Detail as DisplayType);

	if (!loginData.state)
		return <Login handleSucceed={setLoginData} />;

	const setUserType = (userType: UserType) => setLoginData({ state: loginData.state, userType });

	return (
		<UserTypeContext.Provider value={{ type: loginData.userType, changeType: setUserType }}>
			<ContentStatusContext.Provider value={{ status, changeStatus: setStatus }}>
				<DisplayTypeContext.Provider value={{ type: displayType, changeType: setDisplayType }}>
					<Header />
					<Contents />
					<div id="modal"></div>
					<div id="confirm"></div>
				</DisplayTypeContext.Provider>
			</ContentStatusContext.Provider >
		</UserTypeContext.Provider >
	);
}

addEventListener("load", () =>
	GET("welcome")
		.then(r => r.json())
		.then(json => {
			if ("_csrf" in json && typeof json._csrf === 'string' && "loggedIn" in json && typeof json.loggedIn === 'boolean') {
				setCSRFToken(json._csrf);
				ReactDOM.render(<React.StrictMode><App loggedIn={json.loggedIn} userType={json.userType} /></React.StrictMode>, document.getElementById("root"));
			}
			else throw "ログインできません";
		})
		.catch(alert)
);
