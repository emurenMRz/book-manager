import * as React from "react";
import BookImage from '../BookImage';
import { BookInfo } from "../BookData";

export default function DetailCard(props: { book: BookInfo, setBook: Function }) {
	const book = props.book;
	const unregistered = book["from"] == -1;
	return (
		<div className={"book-card book-card--detail" + (unregistered ? " unregistered" : "")} onClick={() => props.setBook(book)}>
			<BookImage isbn={book.isbn} alt={book["書籍名"]} />
			<table>
				<tbody>
					<tr><td className="key">書籍名</td><td className="value">{book["書籍名"]}</td></tr>
					<tr><td className="key">著者</td><td className="value">{book["著者"]}</td></tr>
					<tr><td className="key">レーベル</td><td className="value">{book["レーベル"]}</td></tr>
					<tr><td className="key">発売日</td><td className="value">{book["発売日"]}</td></tr>
					<tr><td className="key">出版社</td><td className="value">{book["出版社"]}</td></tr>
				</tbody>
			</table>
		</div>
	);
}
