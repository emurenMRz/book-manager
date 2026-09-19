import * as React from "react";
import { DisplayType, DisplayTypeContext } from "../context/DisplayType";
import { GET } from "../../utility";
import DetailCard from "./Card/DetailCard";
import SimpleCard from "./Card/SimpleCard";
import ThumbCard from "./Card/ThumbCard";
import BookData, { BookInfo } from "./BookData";
import NextPagePanel, { PageMeta } from "./NextPagePanel";
import Portal from "../../Portal";
import { SearchQuery } from "../header/Search";

export const DataType = {
	UnreadList: "list/unread",
	ToBuyList: "list/to-buy",
	ToBuyUnpublishedList: "list/to-buy/unpublished",
	HoldList: "list/hold",
	SearchList: "search",
} as const;
export type DataType = typeof DataType[keyof typeof DataType];

type Props = {
	dataType: DataType;
	searchQuery?: SearchQuery | null;
};

export default function BookList(props: Props = {
	dataType: DataType.ToBuyList,
	searchQuery: null,
}) {
	const [books, setBooks] = React.useState<BookInfo[] | null>(null);
	const [book, setBook] = React.useState<BookInfo | null>(null);
	const [update, setUpdate] = React.useState(0);
	const [pageMeta, setPageMeta] = React.useState<PageMeta | null>(null);
	const displayType = React.useContext(DisplayTypeContext);
	const reqIdRef = React.useRef(0);

	React.useEffect(() => {
		const reqId = ++reqIdRef.current;
		let api = props.dataType;
		let converter = (json: any) => json;

		if (props.dataType == DataType.SearchList) {
			if (!props.searchQuery) {
				setBooks([]);
				setPageMeta(null);
				return;
			}
			api += `?${Object.entries(props.searchQuery).map(v => `${v[0]}=${encodeURIComponent(v[1])}`).join("&")}`;
			converter = (json: { books: BookInfo[], meta: PageMeta }) => {
				if (pageMeta !== null && json.meta.page > 1) {
					if (json.meta.coverage !== null)
						json.meta.coverage.pages = pageMeta.coverage.pages;
					if (json.meta.rakuten !== null && pageMeta.rakuten !== null)
						json.meta.rakuten.pages = pageMeta.rakuten.pages;
				}
				setPageMeta(json.meta);
				if (books === null || json.meta.page === 1)
					return json.books;
				const newBooks = [...books];
				json.books.forEach((book: BookInfo) => {
					if (!books.some(v => v.isbn === book.isbn))
						newBooks.push(book);
				});
				return newBooks;
			};

			if (pageMeta === null || !("page" in props.searchQuery))
				setBooks(null);
		} else
			setBooks(null)

		GET(api).then(r => r.json())
			.then(json => {
				if (reqId !== reqIdRef.current) return;
				if (json.error)
					throw json.error;
				setBooks(converter(json));
			})
			.catch(e => {
				if (reqId !== reqIdRef.current) return;
				console.error(e);
				setBooks([]);
				setPageMeta(null);
			});
		return () => { reqIdRef.current = reqId + 1; };
	}, [update, props.dataType, props.searchQuery]);

	if (books == null)
		return <div className="notify-board"><span className="notify-board-message">Loading ...</span></div>;
	if (books.length == 0)
		return <div className="notify-board"><span className="notify-board-message">書籍情報が見つかりません</span></div>;

	return (<>
		{(() => {
			if (displayType.type == DisplayType.Thumb)
				return <div className="book-list book-list-thumb">{books.map(book => <ThumbCard key={book.isbn} book={book} setBook={setBook} />)}</div>;
			else if (displayType.type == DisplayType.Simple)
				return <div className="book-list">{books.map(book => <SimpleCard key={book.isbn} book={book} setBook={setBook} />)}</div>;
			return <div className="book-list">{books.map(book => <DetailCard key={book.isbn} book={book} setBook={setBook} />)}</div>;
		})()}
		<NextPagePanel pageMeta={pageMeta} />
		<Portal targetID="modal">
			<BookData dataType={props.dataType} book={book} setBook={setBook} handleUpdate={setUpdate} />
		</Portal>
	</>);
}