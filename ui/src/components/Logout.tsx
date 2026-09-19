import * as React from "react";
import Portal from "../Portal";
import { DELETE, setCSRFToken } from "../utility";

export default function Logout(props: {}) {

	React.useEffect(() => {
		DELETE("logout")
			.then(r => {
				setCSRFToken();
				setTimeout(() => location.reload(), 3 * 1000);
				if (!r.ok) throw new Error("Logout response was not OK");
				const contentType = r.headers.get("Content-Type");
				if (!contentType || !contentType.includes("application/json"))
					throw new Error("Logout response was not JSON");
				return r.json();
			})
			.then(json => {
				if (!json.succeed)
					throw new Error("ログアウト：失敗");
				console.info("ログアウト：成功");
			})
			.catch(console.error);
	}, []);

	return (
		<Portal targetID="modal">
			<div className={"modal modal-base"}>
				<div className="modal-message">ログアウトしました</div>
			</div>
		</Portal>
	);
}