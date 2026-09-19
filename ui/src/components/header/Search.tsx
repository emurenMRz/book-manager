import * as React from "react";
import Portal from "../../Portal";

export type SearchQuery = {
	isbn: string,
	title: string,
	author: string,
	tag: string,
	page: number,
	db: string,
}

export default function Search(props: { handleSetContent: Function }) {
	const [isOpen, setIsOpen] = React.useState(false);
	const refTitle = React.createRef<HTMLInputElement>();
	const refAuthor = React.createRef<HTMLInputElement>();
	const refTag = React.createRef<HTMLInputElement>();

	const handleSearch = () => {
		const title = refTitle.current;
		const author = refAuthor.current;
		const tag = refTag.current;

		const query = {} as SearchQuery;
		if (title?.value.length)
			query[title.value.match(/^[0-9]{13}$/) ? "isbn" : "title"] = title.value;
		if (author?.value.length)
			query.author = author.value;
		if (tag?.value.length)
			query.tag = tag.value;

		if (!Object.keys(query).length)
			alert("検索ワードが指定されていません");
		else {
			if (title) title.value = '';
			if (author) author.value = '';
			if (tag) tag.value = '';
			setIsOpen(false);
			props.handleSetContent({ mode: "Search", searchQuery: query });
		}
	};

	return (<>
		<div className="icon search-button" onClick={() => setIsOpen(true)}></div>
		<Portal targetID="modal">
			<div className={"modal" + (isOpen ? " modal-open" : "")} onClick={() => setIsOpen(false)}>
				<div className={"search-box" + (isOpen ? " search-box-open" : "")} onClick={e => e.stopPropagation()}>
					<span className="headline">検索ワード</span>
					<input ref={refTitle} tabIndex={1} type="text" name="isbn-or-title" className="control" placeholder="ISBN または 書籍名" />
					<input ref={refAuthor} tabIndex={2} type="text" name="author" className="control" placeholder="著者名" />
					<input ref={refTag} tabIndex={3} type="text" name="tag" className="control" placeholder="タグ" />
					<div tabIndex={4} className="button" onClick={handleSearch} onKeyDown={handleSearch}>検索</div>
				</div>
			</div>
		</Portal>
	</>);
}