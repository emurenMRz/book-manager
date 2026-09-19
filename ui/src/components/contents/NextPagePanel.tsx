import * as React from "react";
import { ContentStatusContext, SearchStatus } from "../context/ContentStatus";

type DBMeta = {
	count: number;
	pages: number;
};

export type PageMeta = {
	page: number;
	coverage: DBMeta;
	rakuten: DBMeta | null;
};

type Props = {
	pageMeta: PageMeta | null;
};

export default function NextPagePanel(props: Props) {
	if (props.pageMeta === null)
		return <></>;

	const context = React.useContext(ContentStatusContext);
	const ref = React.createRef<HTMLDivElement>();
	const meta = props.pageMeta;
	const page = +meta.page;

	React.useEffect(() => {
		if (ref.current === null) return;
		const observer = new IntersectionObserver((entries: any) => {
			entries.forEach((entry: any) => {
				if (!entry.intersectionRatio) return;
				const status = context.status as SearchStatus;
				const t = entry.target;
				const searchQuery = { ...status.searchQuery };
				searchQuery.page = t.dataset.nextPage;
				searchQuery.db = t.dataset.targetDb;
				context.changeStatus({ mode: status.mode, searchQuery });
				observer.unobserve(t);
			});
		});
		observer.observe(ref.current);
	}, [page]);

	let db = "";
	if (meta.coverage !== null && page < meta.coverage.pages) db += "c";
	if (meta.rakuten !== null && page < meta.rakuten.pages) db += "r";

	if (!db.length)
		return <></>;

	return (<div ref={ref} className={"next-page-loader"} data-next-page={page + 1} data-target-db={db}>Loading...</div>);
}
