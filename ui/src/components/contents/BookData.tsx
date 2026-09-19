import * as React from 'react';
import BookImage from './BookImage';
import { PUT, PATCH, DELETE } from '../../utility';
import { DataType } from './BookList';
import Portal from '../../Portal';

export type BookInfo = {
	"isbn": string; // 0
	"from": number; // 1
	"登録日"?: string; // 2
	"読了日"?: string; // 3
	"既読"?: number; // 4
	"所有"?: number; // 5
	"購入予定"?: string; // 6
	"評価"?: number; // 7
	"貸出先"?: string; // 8
	// "タグ": string; // 9
	"コメント"?: string; // 10
	"書籍名": string; // 11
	"レーベル"?: string; // 12
	"著者"?: string; // 13
	"著者（読み）"?: string; // 14
	"価格"?: number; // 15
	"判型"?: string; // 16
	"ページ数"?: number; // 17
	"出版社"?: string; // 18
	"発売日"?: string; // 19
	"説明"?: string; // 20
	"タグ"?: string; // 21
};

export const ConfirmMode = {
	Close: 0,
	Delete: 1,
	Add: 2,
	Description: 3,
} as const;
export type ConfirmMode = typeof ConfirmMode[keyof typeof ConfirmMode];

const UserEXData = (props: { book: BookInfo, change: Function }) => {
	if (props.book.from < 0) return null;
	const book = props.book;
	const makeList = (list: string[]) => list.map((v, i) => <option key={i} value={i}>{v}</option>);
	return (<>
		<div className="row-group">
			<div className="item"><header>登録日</header><span className="date">{book["登録日"]}</span></div>
			<div className="item"><header>読了日</header><span className="date">{book["読了日"]}</span></div>
			<div className="item"><header>既読</header><select name="readed" id="readed" defaultValue={book["既読"]} onChange={event => props.change("既読", event)}>{makeList(["未読", "既読", "未読了"])}</select></div>
			<div className="item"><header>所有</header><select name="owned" id="owned" defaultValue={book["所有"]} onChange={event => props.change("所有", event)}>{makeList(["未所有", "所有", "借物", "貸出中", "売却済"])}</select></div>
		</div>
		<div className="row-group">
			<div className="item"><header>貸出先</header><input type="text" name="recipient" id="recipient" defaultValue={book["貸出先"]} onChange={event => props.change("貸出先", event)} /></div>
			<div className="item"><header>購入予定</header>
				<select name="purchasePlan" id="purchasePlan" defaultValue={book["購入予定"] ? "t" : "f"} onChange={event => props.change("購入予定", event)}>
					<option key="0" value="f">なし</option>
					<option key="1" value="t">あり</option>
				</select>
			</div>
			<div className="item"><header>評価</header><select name="evaluation" id="evaluation" defaultValue={book["評価"]} onChange={event => props.change("評価", event)}>{makeList(["保留", "駄作", "凡作", "佳作", "良作", "傑作"])}</select></div>
		</div>
		<div className="row-group">
			<div className="item"><header>タグ</header><input className="input-box" type="text" name="tag" id="tag" placeholder="タグごとに','で区切ってください" defaultValue={book["タグ"]} onChange={event => props.change("タグ", event)} /></div>
		</div>
		<div className="row-group">
			<div className="item"><header>コメント</header><textarea className="input-box" name="comment" id="comment" defaultValue={book["コメント"]} onChange={event => props.change("コメント", event)} /></div>
		</div>
	</>);
};

const Command = (props: { dataType: DataType, book: BookInfo, handleEdit: Function, displayConfirm: Function }) => (
	<div className="button-group">
		<div className="button" onClick={() => props.handleEdit()}>閉じる</div>
		{props.dataType == DataType.UnreadList
			? <div className="button" onClick={() => props.handleEdit(1)}>読了！</div>
			: props.dataType == DataType.ToBuyList
				? <div className="button" onClick={() => props.handleEdit(2)}>購入済</div>
				: null}
		<div className="spacer"></div>
		{props.book["説明"] && props.book["説明"].length > 0
			? <div className="icon description-button" onClick={() => props.displayConfirm(ConfirmMode.Description)}></div>
			: null}
		{props.book.from < 0
			? <div className="icon add-button" onClick={() => props.displayConfirm(ConfirmMode.Add)}></div>
			: <div className="icon delete-button" onClick={() => props.displayConfirm(ConfirmMode.Delete)}></div>}
	</div>
);

const Confirm = (props: { book: BookInfo, confirmMode: ConfirmMode, handleDelete: Function, handleRegister: Function, displayConfirm: Function }) => {
	switch (props.confirmMode) {
		case ConfirmMode.Delete:
			return (<>
				<div className="confirm-message">
					削除しますか？<br />
					※自分で編集した内容は再登録しても復元されません
				</div>
				<div className="button-group">
					<div className="button" onClick={() => props.handleDelete()}>削除する</div>
					<div className="button" onClick={() => props.displayConfirm(ConfirmMode.Close)}>そのまま</div>
				</div>
			</>);

		case ConfirmMode.Add:
			return (<>
				<div className="confirm-message">
					蔵書一覧に登録しますか？<br />
					※「購入予定」に追加されます
				</div>
				<div className="button-group">
					<div className="button" onClick={() => props.handleRegister()}>登録する</div>
					<div className="button" onClick={() => props.displayConfirm(ConfirmMode.Close)}>登録しない</div>
				</div>
			</>);

		case ConfirmMode.Description:
			return (<>
				<div className="confirm-description">{props.book["説明"]}</div>
				<div className="button-group">
					<div className="button" onClick={() => props.displayConfirm(ConfirmMode.Close)}>閉じる</div>
				</div>
			</>);
	}
	return null;
};

export default function BookData(props: { dataType: DataType, book: BookInfo | null, setBook: Function, handleUpdate: Function }) {
	if (!props.book)
		return null;

	const [confirmMode, displayConfirm] = React.useState<ConfirmMode>(ConfirmMode.Close);
	const book = props.book;
	const params: { [key: string]: string | number | boolean } = {};
	const change = (name: string, event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => params[name] = (document.getElementById(event.currentTarget.name) as HTMLInputElement | HTMLSelectElement).value;

	const handleRegister = () => {
		const apply = (name: string) => {
			if (!(name in book)) return;
			const data = book[name as keyof BookInfo];
			if (data === undefined) return;
			if (typeof data === 'string' && data.length == 0) return;
			params[name] = data;
		};

		apply("isbn");
		apply("書籍名");
		apply("レーベル");
		apply("著者");
		apply("著者（読み）");
		apply("価格");
		apply("判型");
		apply("ページ数");
		apply("出版社");
		apply("発売日");

		PUT(`book/register`, Object.entries(params).map(v => `${encodeURIComponent(v[0])}=${encodeURIComponent(v[1])}`).join("&"))
			.then(r => props.handleUpdate(Math.random()))
			.catch(console.error);
		displayConfirm(ConfirmMode.Close);
		props.setBook(null);
	};

	const handleEdit = (selectedMode: number = -1) => {
		switch (selectedMode) {
			case 1:
				params["既読"] = 1;
				break;

			case 2:
				params["所有"] = 1;
				params["購入予定"] = false;
				break;
		}

		const query = Object.entries(params);
		if (query.length > 0)
			PATCH(`book/${book.isbn}`, query.map(v => `${encodeURIComponent(v[0])}=${encodeURIComponent(v[1])}`).join("&"))
				.then(r => props.handleUpdate(Math.random()))
				.catch(console.error);
		props.setBook(null);
	};

	const handleDelete = () => {
		DELETE(`book/${book.isbn}`)
			.then(r => props.handleUpdate(Math.random()))
			.catch(console.error);
		displayConfirm(ConfirmMode.Close);
		props.setBook(null);
	};

	return (<>
		<div className={"modal book-data-base" + (book ? " modal-open" : "")} onClick={() => props.setBook(null)}>
			<div className={"book-data" + (book ? " book-data-open" : "")} onClick={e => e.stopPropagation()}>
				<div className="book-basic-data">
					<BookImage isbn={book.isbn} alt={book["書籍名"]} />
					<table>
						<tbody>
							<tr><td className="key">書籍名</td><td className="value">{book["書籍名"]}</td></tr>
							<tr><td className="key">著者</td><td className="value">{book["著者"]}</td></tr>
							<tr><td className="key">著者かな</td><td className="value">{book["著者（読み）"]}</td></tr>
							<tr><td className="key">レーベル</td><td className="value">{book["レーベル"]}</td></tr>
							<tr><td className="key">発売日</td><td className="value">{book["発売日"]}</td></tr>
							<tr><td className="key">価格</td><td className="value">{book["価格"]}</td></tr>
							<tr><td className="key">ISBN</td><td className="value">{book.isbn}</td></tr>
							<tr><td className="key">出版社</td><td className="value">{book["出版社"]}</td></tr>
							<tr><td className="key">判型</td><td className="value">{book["判型"]}</td></tr>
							<tr><td className="key">ページ数</td><td className="value">{book["ページ数"] == 0 ? '' : book["ページ数"]}</td></tr>
						</tbody>
					</table>
				</div>
				<UserEXData book={book} change={change} />
				<Command dataType={props.dataType} book={book} handleEdit={handleEdit} displayConfirm={displayConfirm} />
			</div>
		</div >
		<Portal targetID="confirm">
			<div className={"confirm" + (confirmMode ? " confirm-open" : "")}>
				<Confirm book={book} confirmMode={confirmMode} handleDelete={handleDelete} handleRegister={handleRegister} displayConfirm={displayConfirm} />
			</div>
		</Portal>
	</>);
}
