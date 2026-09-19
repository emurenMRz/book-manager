import * as React from "react";
import BookImage from '../BookImage';
import { BookInfo } from "../BookData";

export default function ThumbCard(props: { book: BookInfo, setBook: Function }) {
	const book = props.book;
	const unregistered = book["from"] == -1;
	return (
		<div className={"book-card book-card--thumb" + (unregistered ? " unregistered" : "")} onClick={() => props.setBook(book)}>
			<BookImage isbn={book.isbn} alt={book["書籍名"]} />
		</div>
	);
}
