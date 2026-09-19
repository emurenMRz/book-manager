import * as React from "react";
import Portal from "../../Portal";
import { DisplayType, DisplayTypeContext } from "../context/DisplayType";
import { UserType, UserTypeContext } from "../context/UserType";
import { TargetData } from "../contents/ChangeUserData";

export default function Menu(props: { handleSetContent: Function }) {
	const [isOpen, setIsOpen] = React.useState(false);
	const refType = React.createRef<HTMLSelectElement>();
	const displayType = React.useContext(DisplayTypeContext);
	const userType = React.useContext(UserTypeContext);
	const handleChangeDisplayMode = () => {
		setIsOpen(false);
		displayType.changeType(refType.current?.value as DisplayType);
	};
	const handleButton = (mode: string, target?: TargetData) => {
		setIsOpen(false);
		const param: { mode: string, target?: TargetData } = { mode };
		if (target)
			param.target = target;
		props.handleSetContent(param);
	};

	const InnerMenu = (props: { handleButton: Function }) => {
		if (userType.type == UserType.Temp)
			return <div className="button" onClick={() => props.handleButton("ChangeUserData", TargetData.Register)}>正式登録</div>;
		if (userType.type == UserType.Regular)
			return (<>
				<div className="button" onClick={() => props.handleButton("ChangeUserData", TargetData.UserName)}>アカウント名の変更</div>
				<div className="button" onClick={() => props.handleButton("ChangeUserData", TargetData.Password)}>パスワードの変更</div>
			</>)
		return null;
	};

	return (<>
		<div className="icon menu-button" onClick={() => setIsOpen(true)}></div>
		<Portal targetID="modal">
			<div className={"modal" + (isOpen ? " modal-open" : "")} onClick={() => setIsOpen(false)}>
				<div className={"menu-box" + (isOpen ? " menu-box-open" : "")} onClick={e => e.stopPropagation()}>
					<span className="headline">書籍リストの表示方法</span>
					<select ref={refType} name="displayType" className="control" onChange={() => handleChangeDisplayMode()}>
						<option value={DisplayType.Detail}>通常</option>
						{/* <option value={DisplayType.Simple}>シンプル</option> */}
						<option value={DisplayType.Thumb}>サムネイル</option>
					</select>
					<InnerMenu handleButton={handleButton} />
					{/* <div className="button" onClick={() => handleButton("Contact")}>お問い合せ</div> */}
					<div className="button" onClick={() => handleButton("Logout")}>ログアウト</div>
				</div>
			</div>
		</Portal>
	</>);
}