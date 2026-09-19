import * as React from "react";
import { ContentStatusContext } from '../context/ContentStatus'

import Menu from "./Menu";
import Mode from "./Mode";
import Search from "./Search";

export default function Header() {
	const context = React.useContext(ContentStatusContext);
	return (
		<div className="header">
			<Menu handleSetContent={context.changeStatus} />
			<Mode status={context.status} handleSetContent={context.changeStatus} />
			<Search handleSetContent={context.changeStatus} />
		</div>
	);
}