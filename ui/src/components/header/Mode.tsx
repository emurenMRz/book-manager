import * as React from "react";
import { ContentStatus } from "../context/ContentStatus";
import { DataType } from "../contents/BookList";

export default function Mode(props: { status: ContentStatus, handleSetContent: Function }) {
	const searchResult = '*search result*';
	const mode = props.status.mode == "BookList" ? props.status.dataType : searchResult;
	const handleClick = (dataType: string) => props.handleSetContent({ mode: "BookList", dataType });

	return (
		<div className="mode">
			<div className={"button" + (mode == DataType.UnreadList ? " button-enable" : "")} onClick={() => handleClick(DataType.UnreadList)}>未読</div>
			<div className={"button" + (mode == DataType.ToBuyList ? " button-enable" : "")} onClick={() => handleClick(DataType.ToBuyList)}>購入予定</div>
			<div className={"button" + (mode == DataType.ToBuyUnpublishedList ? " button-enable" : "")} onClick={() => handleClick(DataType.ToBuyUnpublishedList)}>購入予定（発売前）</div>
			<div className={"button" + (mode == DataType.HoldList ? " button-enable" : "")} onClick={() => handleClick(DataType.HoldList)}>保留</div>
			<select className="control" defaultValue={mode} onChange={e => handleClick(e.currentTarget.value)}>
				<option value={DataType.UnreadList}>未読</option>
				<option value={DataType.ToBuyList}>購入予定</option>
				<option value={DataType.ToBuyUnpublishedList}>購入予定（発売前）</option>
				<option value={DataType.HoldList}>保留</option>
				<option value={searchResult}>検索結果</option>
			</select>
		</div >
	);
}