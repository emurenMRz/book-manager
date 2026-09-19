import * as React from "react";
import { DataType } from "./BookList";
import { PATCH } from "../../utility";
import { UserType, UserTypeContext } from "../context/UserType";

export const TargetData = {
	UserName: "name",
	Password: "password",
	Register: "register",
} as const;
export type TargetData = typeof TargetData[keyof typeof TargetData];

export default function ChangeUserData(props: { target: TargetData, handleSetContent: Function }) {
	const userType = React.useContext(UserTypeContext);
	const refValue1 = React.createRef<HTMLInputElement>();
	const refValue2 = React.createRef<HTMLInputElement>();
	const refNotice = React.createRef<HTMLDivElement>();

	const handleAlter = () => {
		const value1 = refValue1.current;
		const value2 = refValue2.current;
		if (!value1 || !value2)
			return;

		const isRegisterMode = props.target == TargetData.Register;

		PATCH(`user/${props.target}`, isRegisterMode ? `name=${value1.value}&pw=${value2.value}` : `now=${value1.value}&new=${value2.value}`)
			.then(r => r.json())
			.then((json: { succeed: boolean, _csrf: string, error: string }) => {
				if (json.error) throw json.error;
				if (!json.succeed) throw "セッションIDが取得できません";
				if (isRegisterMode) userType.changeType(UserType.Regular);
				props.handleSetContent({ mode: "BookList", dataType: DataType.ToBuyList });
			})
			.catch((e: Error | string) => {
				if (typeof e == 'string' && refNotice && refNotice.current)
					refNotice.current.textContent = e;
				else
					console.error(e);
			});
	};

	const changeType = () => (<>
		<div className="title">正式登録</div>
		<input ref={refValue1} tabIndex={1} type="text" placeholder="新しいユーザー名" />
		<input ref={refValue2} tabIndex={2} type="password" placeholder="新しいパスワード" />
	</>);

	const changeName = () => (<>
		<div className="title">ユーザー名の変更</div>
		<input ref={refValue1} tabIndex={1} type="password" placeholder="現在のパスワード" />
		<input ref={refValue2} tabIndex={2} type="text" placeholder="新しいユーザー名" />
	</>);

	const changePW = () => (<>
		<div className="title">パスワードの変更</div>
		<input ref={refValue1} tabIndex={1} type="password" placeholder="現在のパスワード" />
		<input ref={refValue2} tabIndex={2} type="password" placeholder="新しいパスワード" />
	</>);

	const InputElements = (props: { target: TargetData }) => {
		switch (props.target) {
			case TargetData.UserName: return changeName();
			case TargetData.Password: return changePW();
			case TargetData.Register: return changeType();
		}
	};

	return (
		<div className="change-userdata-base">
			<form className="change-userdata" onSubmit={handleAlter}>
				<InputElements target={props.target} />
				<div ref={refNotice} className="notice"></div>
				<div className="button-group">
					<div tabIndex={3} className="button" onClick={handleAlter} onKeyDown={handleAlter}>変更</div>
				</div>
			</form>
		</div>
	);
}