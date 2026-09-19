import * as React from "react";
import { ContentStatusContext } from "../context/ContentStatus";
import BookList, { DataType } from "./BookList";
import ChangeUserData from "./ChangeUserData";
import Logout from "../Logout";

function Contact(props: {}) { return <div>Contact</div>; }

export default function Contents() {
	const context = React.useContext(ContentStatusContext);
	switch (context.status.mode) {
		case "BookList": return <div id="contents"><BookList dataType={context.status.dataType} /></div>;
		case "Search": return <div id="contents"><BookList dataType={DataType.SearchList} searchQuery={context.status.searchQuery} /></div>;
		case "ChangeUserData": return <div id="contents"><ChangeUserData target={context.status.target} handleSetContent={context.changeStatus} /></div>;
		case "Contact": return <div id="contents"><Contact /></div>;
		case "Logout": return <div id="contents"><Logout /></div>;
		default: throw new Error("Unknown Contents");
	}
}