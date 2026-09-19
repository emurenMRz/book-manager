import * as React from "react";
import { BookInfo } from "../BookData";

export default function SimpleCard(props: { book: BookInfo, setBook: Function }) {
	const book = props.book;
	const unregistered = book["from"] == -1;
	return (
		<div className={"book-card book-card--simple" + (unregistered ? " unregistered" : "")} onClick={() => props.setBook(book)}>
			<div className="date">{book["発売日"]}</div>
			<div className="title">{book["書籍名"]}</div>
		</div>
	);
}
